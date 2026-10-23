# Flash

Flash is an unofficial derivative of [FlClash](https://github.com/chen08209/FlClash).
Exact upstream and Core revisions are recorded in flash/upstream.json and the
SOURCE_REVISION files distributed with each package.
Modified 2026-10-23 by CodeAIX for macOS status presentation.

The original GPL-3.0 LICENSE and upstream copyright notices are retained.
FlClash, mihomo, Flutter and the bundled third-party projects remain credited
under their respective notices. No AiGuard source or artwork was copied. The Flash app icon recolors the credited
FlClash glyph with emerald, jade and mint gradients on a white tile.
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
follow-up work; status-icon behavior and the revision 2 backup/channel fixes have been user-tested.

## GitHub builds and releases

`Build Flash macOS` builds arm64 and x86_64 Release DMGs on GitHub Actions.
These run in normal network mode (SAFE_MODE=false), use ad-hoc signing, and are
not notarized. Artifacts include GPL/derivative notices, SHA256SUMS, an exact
source revision record, and a source archive including the pinned Core submodule.
Published builds are not a claim of completed runtime acceptance.
Inherited publishing workflows are retained under `.github/upstream-workflows/`
as references and do not execute for Flash.

## 1.9.1 revision 2

The macOS packaging signature retains nested entitlements and explicitly applies
Runner release entitlements, verified after signing. Stable builds set
APP_ENV=stable. Remote restore prefers /Flash/<file> and only on HTTP 404/409
tries the legacy /FlClash/<file> without modifying the remote backup. Authentication
and other server errors remain errors. The original v1.9.1 release is retained;
v1.9.1+2026102302 uses application build 2026102302.

## 1.9.1 revision 3

Application build 2026102303 adds the approved green-gradient app icon to the
macOS application catalog and the in-app About view. The vector master is
flash/branding/app-icon.svg; tool/flash/generate_icon.py renders all sizes.
The app icon and status-bar icon are separate resources. This revision retains
the revision 2 backup, signing-entitlement and stable-channel repairs, confirmed
by the user. The upstream glyph geometry and license attribution are preserved.

## 1.9.1 revision 4

Application build 2026102304 corrects the app-icon tile geometry. The original
FlClash per-size macOS backgrounds, alpha masks, margins and subtle shadows are
retained in flash/branding/tiles, with source hashes in provenance.json. The
approved green vector glyph is composited on those tiles. This replaces the
revision 3 approximate corner path while retaining its green palette and glyph
geometry. Original GPL attribution applies to the inherited tile resources.

## 1.9.1 revision 5

Application build 2026102305 softens the native status badge corners (4 to 6 pt)
and increases country-code / error text from 11 pt Bold to 12.5 pt Heavy.
The 26 × 18 pt icon footprint and all state/color semantics are retained.
The revision 4 application-icon tile and the earlier backup repairs remain.
