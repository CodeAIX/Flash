# Flash overlay maintenance

`runtime-paths.txt` is the explicit list of runtime, platform-identity and regression-test files maintained by Flash. `runtime.patch` is a full-index three-way Git patch against the fixed upstream commit in `upstream.json`. It excludes version metadata, repository docs and workflow glue.

To refresh it after changing Flash runtime code (including added/deleted files), update the path list and run:

```sh
git diff --binary --full-index "$(python3 -c "import json; print(json.load(open('flash/upstream.json'))['commit'])")" -- $(cat flash/runtime-paths.txt) > flash/runtime.patch
python3 tool/flash/sync_upstream.py --validate-overlay
```

The validation reconstructs the declared runtime files from clean upstream and compares them byte-for-byte with the current checkout. It does not prove compatibility with future upstream versions.

The scheduled workflow checks stable releases daily. The updater applies the patch with `git apply --3way --index`, copies Flash docs/workflows/maintenance metadata, derives the version, refreshes the patch against the new upstream tag and opens a candidate PR. The PR build is explicitly dispatched because events created by GITHUB_TOKEN do not trigger normal PR workflows.

Publishing requires both architecture jobs to succeed. A sync PR is merged only with its exact built head SHA; publication tags the exact built source commit. Conflicts, tests/build failures or merge failures stop publication. No force push or destructive reset is used.

If repository policy blocks Actions from creating PRs or merging them, enable the corresponding repository setting; failures stay visible in the sync run/PR. No external token is stored in source.

macOS packaging currently pins Flutter 3.47.6 and Go 1.27.1 and chooses an installed Xcode 26 SDK. A future upstream toolchain or tray/provider API change can require manual adaptation. Windows/Android are not yet Flash release targets.
