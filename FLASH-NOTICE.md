# Flash (development preview)

Flash is an unofficial derivative of [FlClash](https://github.com/chen08209/FlClash).
Upstream v0.9.1, commit 8d4f9744948751f1273fe871e1d05276fac09b0e;
Clash.Meta submodule 8380d0e7462f061a964323e9bf3129a236fcc5d5.
Modified 2026-10-22 by CodeAIX for macOS status presentation.

The original GPL-3.0 LICENSE and upstream copyright notices are retained.
FlClash, mihomo, Flutter and the bundled third-party projects remain credited
under their respective notices. No AiGuard source or artwork was copied.
When distributing a binary, provide its exact corresponding source, submodule
revisions and build scripts under the applicable licenses.

The macOS app is named Flash with com.codeaix.flash (debug suffix in Debug).
The internal Core executable name is retained. Updates point to CodeAIX/Flash;
that repository must exist and contain Flash releases before enabling distribution.
No release has been published by this change. Windows and Android identities
are not yet adapted and are not Flash distribution targets.

## Current status semantics

- Blue: the Core's rule-routed IP lookup succeeded and an OS entry is configured.
- Orange: lookup succeeded but neither TUN nor system proxy is configured.
- Red: lookup failed. No claim of direct routing or Chinese egress is made.
- Gray: stopped, suspended, pending or unknown; country is --.

OS entry configuration is not a path test. No green state is claimed. A lookup
only describes the route used by its particular test URL, not every app or AI
service. Tooltip names this evidence boundary. Country validation happens again
in the native renderer. The native image is non-template, Retina-scaled by AppKit.

The tray holds the existing route tracker while hidden, reuses OutboundIpProbe,
refreshes every 60 seconds while running, and releases its timer/watch on stop
or disposal. Route stamps reject superseded answers. During refresh the display
is gray instead of presenting the retained cache as a new measurement.
Upstream probe providers/services and their endpoint list are unchanged.

The first preview retains upstream menus, group actions and speed title.
Build with --dart-define=FLASH_STATUS_ICON=false to restore upstream template
icons and disable the tray background subscription. A persisted UI option,
backoff, independent OS path verification and real-network acceptance remain
follow-up work before release.

## GitHub preview builds

`Build Flash macOS` builds arm64 and x86_64 Release DMGs on GitHub Actions.
These run in normal network mode (SAFE_MODE=false), use ad-hoc signing, and are
not notarized. Artifacts include GPL/derivative notices, SHA256SUMS, an exact
source revision record, and a source archive including the pinned Core submodule.
They are development previews, not a claim of completed runtime acceptance.
Inherited publishing workflows are retained under `.github/upstream-workflows/`
as references and do not execute for Flash.
