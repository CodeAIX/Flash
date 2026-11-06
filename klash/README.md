# Klash overlay maintenance

`runtime-paths.txt` is the explicit list of runtime, platform-identity and regression-test files maintained by Klash. `runtime.patch` is a full-index three-way Git patch against the fixed upstream commit in `upstream.json`. It excludes version metadata, repository docs and workflow glue.

To refresh it after changing Klash runtime code (including added/deleted files), update the path list and run:

```sh
git diff --binary --full-index "$(python3 -c "import json; print(json.load(open('klash/upstream.json'))['commit'])")" -- $(cat klash/runtime-paths.txt) > klash/runtime.patch
python3 tool/klash/sync_upstream.py --validate-overlay
```

The validation reconstructs the declared runtime files from clean upstream and compares them byte-for-byte with the current checkout. It does not prove compatibility with future upstream versions.

The scheduled workflow checks stable releases daily. The updater applies the patch with `git apply --3way --index`, copies Klash docs/workflows/maintenance metadata, derives the version, refreshes the patch against the new upstream tag and opens a candidate PR. The PR build is explicitly dispatched because events created by GITHUB_TOKEN do not trigger normal PR workflows.

Publishing requires both architecture jobs to succeed. A sync PR is merged only with its exact built head SHA; publication tags the exact built source commit. Conflicts, tests/build failures or merge failures stop publication. No force push or destructive reset is used.

If repository policy blocks Actions from creating PRs or merging them, enable the corresponding repository setting; failures stay visible in the sync run/PR. No external token is stored in source.

macOS packaging currently pins Flutter 3.47.6 and Go 1.27.1 and chooses an installed Xcode 26 SDK. A future upstream toolchain or tray/provider API change can require manual adaptation. Windows/Android are not yet Klash release targets.

## v0.9.2 integration

The fork-wide Actions suspension was lifted by the maintainer on 2026-10-29. The resumed scheduled sync correctly stopped on overlay conflicts. This upgrade keeps the approved Klash PNGs, combines upstream fallback tray behavior with Klash badges, and regenerates provider outputs. The upstream monochrome option is hidden while Klash badges are active, since badge color conveys entry state. Future source conflicts still require review; automatic publication is gated by both macOS builds.

Reconstructed candidates retain the current Klash release commit as an ancestor with an `ours` strategy merge after the upstream-plus-overlay tree is committed. This preserves the reviewed candidate tree while allowing the gated PR to merge without reapplying the previous Klash overlay as a competing branch.

## Klash rename and glyph rendering (2026-11-06)

Klash continues the Flash overlay with a new product/bundle/repository identity. Old WebDAV roots and the previous monitor preference key are read-only compatibility inputs. Private upstream module/Core/IPC names remain intact. No active-data-directory migration is performed.

Country paths are prepared once from the system monospaced Heavy font. The image callback only fills paths and the existing logo/background. The native harness calibrates baseline and optical weight against the previous renderer; its test-only reference uses NSString, while production does not.

Compile tool/klash/test_status_image.swift as /tmp/main.swift together with the production KlashStatusImage.swift to run the glyph test. Both Core and prism_ui sources are included in release archives.

.github/workflows/flash-macos.yml and flash-upstream.yml remain stable dispatch IDs. Display names, metadata paths and artifacts use Klash.
