#!/usr/bin/env python3
"""Reconstruct a Flash candidate from an upstream release and the reviewed overlay."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]


def run(*args, cwd=ROOT, check=True):
    return subprocess.run(args, cwd=cwd, check=check, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def version(tag):
    match = re.fullmatch(r'v?(\d+)\.(\d+)\.(\d+)', tag)
    if not match:
        raise ValueError(f'Unsupported stable upstream tag: {tag}')
    parts = tuple(map(int, match.groups()))
    return parts, f'{parts[0] + 1}.{parts[1]}.{parts[2]}'


def reconstruct(tag, destination, paths):
    run('git', 'worktree', 'add', '--detach', str(destination), tag)
    result = run('git', 'apply', '--3way', '--index', str(ROOT / 'flash/runtime.patch'), cwd=destination, check=False)
    if result.returncode:
        raise RuntimeError(f'Flash overlay conflict; no candidate published:\n{result.stderr}')
    for relative in paths:
        original = ROOT / relative
        target = destination / relative
        if original.exists() and not target.exists():
            raise RuntimeError(f'Overlay lost {relative}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--validate-overlay', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'flash/upstream.json').read_text())
    paths = (ROOT / 'flash/runtime-paths.txt').read_text().splitlines()
    if args.validate_overlay:
        tag = manifest['commit']
        release = None
    else:
        release = json.loads(run('gh', 'api', f'repos/{manifest["repository"]}/releases/latest').stdout)
        if release['draft'] or release['prerelease']:
            return
        tag = release['tag_name']
        if version(tag)[0] <= version(manifest['tag'])[0]:
            print('No newer stable upstream release')
            return
        run('git', 'fetch', f'https://github.com/{manifest["repository"]}.git', f'refs/tags/{tag}:refs/tags/{tag}')
    temporary = Path(tempfile.mkdtemp(prefix='flash-overlay-'))
    destination = temporary / 'candidate'
    try:
        reconstruct(tag, destination, paths)
        if args.validate_overlay:
            for relative in paths:
                expected, actual = ROOT / relative, destination / relative
                if expected.exists() != actual.exists() or (expected.exists() and expected.read_bytes() != actual.read_bytes()):
                    raise RuntimeError(f'Overlay differs from current runtime file: {relative}')
            print('Flash runtime overlay reconstructs all declared files')
            return
        upstream_commit = run('git', 'rev-parse', 'HEAD', cwd=destination).stdout.strip()
        flash_version = version(tag)[1]
        repository = os.environ['GITHUB_REPOSITORY']
        branch = f'codex/upstream-{tag}'
        existing = json.loads(run('gh', 'pr', 'list', '--repo', repository, '--head', branch, '--state', 'open', '--json', 'number').stdout)
        if existing:
            print(f'Candidate PR already exists: {existing[0]["number"]}')
            return
        if run('gh', 'release', 'view', f'v{flash_version}', '--repo', repository, check=False).returncode == 0:
            raise RuntimeError('Flash release already exists; refusing to replace it')
        shutil.rmtree(destination / '.github/workflows', ignore_errors=True)
        for relative in ['.github/workflows', '.github/upstream-workflows', 'flash', 'tool/flash']:
            shutil.copytree(ROOT / relative, destination / relative, dirs_exist_ok=True)
        for relative in ['README.md', 'README_zh_CN.md', 'FLASH-NOTICE.md']:
            shutil.copy2(ROOT / relative, destination / relative)
        manifest.update(tag=tag, commit=upstream_commit, flash_version=flash_version)
        (destination / 'flash/upstream.json').write_text(json.dumps(manifest, indent=2) + '\n')
        spec = destination / 'pubspec.yaml'
        spec.write_text(re.sub(r'^version: .*$', f'version: {flash_version}+{int(time.time())}', spec.read_text(), flags=re.M))
        patch = run('git', 'diff', '--binary', '--full-index', tag, '--', *paths, cwd=destination).stdout
        (destination / 'flash/runtime.patch').write_text(patch)
        run('git', 'add', '-A', cwd=destination)
        run('git', 'commit', '-m', f'feat(upstream): integrate {tag} as Flash {flash_version}', cwd=destination)
        run('git', 'push', 'origin', f'HEAD:refs/heads/{branch}', cwd=destination)
        body = temporary / 'pr.md'
        body.write_text(f'Upgrade to {manifest["repository"]} {tag} ({upstream_commit}).\n\nThe Flash overlay applied without unresolved conflicts. Publication requires analysis, tests and both macOS builds. A failed check leaves this PR open.\n')
        base = run('gh', 'repo', 'view', repository, '--json', 'defaultBranchRef', '--jq', '.defaultBranchRef.name').stdout.strip()
        run('gh', 'pr', 'create', '--repo', repository, '--base', base, '--head', branch, '--title', f'Flash {flash_version} from FlClash {tag}', '--body-file', str(body))
        number = json.loads(run('gh', 'pr', 'list', '--repo', repository, '--head', branch, '--json', 'number').stdout)[0]['number']
        run('gh', 'workflow', 'run', 'flash-macos.yml', '--repo', repository, '--ref', branch, '-f', 'publish=true', '-f', f'sync_pr={number}')
        print(f'Created PR {number} and dispatched Flash {flash_version} build')
    finally:
        run('git', 'worktree', 'remove', '--force', str(destination), check=False)
        shutil.rmtree(temporary, ignore_errors=True)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        detail = getattr(error, 'stderr', '')
        raise SystemExit(f'{error}\n{detail}')
