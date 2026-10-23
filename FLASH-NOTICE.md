# Flash

Flash is an unofficial derivative of [FlClash](https://github.com/chen08209/FlClash).
Exact upstream and Core revisions are recorded in flash/upstream.json and the
SOURCE_REVISION files distributed with each package.
Modified 2026-10-23 by CodeAIX for macOS status presentation.

The original GPL-3.0 LICENSE and upstream copyright notices are retained.
FlClash, mihomo, Flutter and the bundled third-party projects remain credited
under their respective notices. No AiGuard source or artwork was copied.
When distributing a binary, provide its exact corresponding source, submodule
revisions and build scripts under the applicable licenses.

The macOS app is named Flash with com.codeaix.flash (debug suffix in Debug).
The internal Core executable name is retained. Updates point to CodeAIX/Flash;
that repository must exist and contain Flash releases before enabling distribution.
Windows and Android identities
are not yet adapted and are not Flash distribution targets.

## Current status semantics

- Green background: TUN is configured on, regardless of system proxy.
- Blue background: TUN is off and system proxy is configured on.
- Orange background: both TUN and system proxy are configured off.
- White country text: the current valid IP has built-in quality rating `good`.
- Black country text: another rating, unknown, loading or failed quality lookup.
- Gray with the upstream-style glyph: stopped or suspended.
- Red F on a neutral rounded rectangle: outbound lookup failed.
- Pending or unknown country is --; the background still reflects entry settings.

Background colors describe entry configuration, not an independent OS path test.
Text color describes quality, not proxy reachability.
A lookup
only describes the route used by its particular test URL, not every app or AI
service. Tooltip names this evidence boundary. Country validation happens again
in the native renderer. The native image is a rounded rectangle, non-template and Retina-scaled by AppKit.
Stopped-state glyph geometry follows the credited upstream glyph.svg.
Quality subscriptions follow the current IP and are released on stop/disposal;
loading, failure or an answer for another IP cannot turn the country text white.

The tray holds the existing route tracker while hidden, reuses OutboundIpProbe,
refreshes every 60 seconds while running, and releases its timer/watch on stop
or disposal. Route stamps reject superseded answers. During refresh the country is -- instead of presenting the retained cache as a new measurement.
Upstream probe providers/services and their endpoint list are unchanged.

The first preview retains upstream menus, group actions and speed title.
Build with --dart-define=FLASH_STATUS_ICON=false to restore upstream template
icons and disable the tray background subscription. A persisted UI option,
backoff, independent OS path verification and real-network acceptance remain
follow-up work; normal-network runtime acceptance remains pending.

## GitHub builds and releases

`Build Flash macOS` builds arm64 and x86_64 Release DMGs on GitHub Actions.
These run in normal network mode (SAFE_MODE=false), use ad-hoc signing, and are
not notarized. Artifacts include GPL/derivative notices, SHA256SUMS, an exact
source revision record, and a source archive including the pinned Core submodule.
Published builds are not a claim of completed runtime acceptance.
Inherited publishing workflows are retained under `.github/upstream-workflows/`
as references and do not execute for Flash.
