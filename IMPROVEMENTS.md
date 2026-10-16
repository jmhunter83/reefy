# What Reefy adds on top of Swiftfin

Reefy is a tvOS-only fork of [Swiftfin](https://github.com/jellyfin/swiftfin). It tracks
upstream closely and merges from it rather than drifting — the current base is Swiftfin
**`main` at `be3ce011`** (past 1.6.1), merged 2026-09-27. The previous base was 1.5
(`7891e273`), adopted 2026-07-26 for Reefy 2.0.

Everything below is a deliberate divergence from that base. Anything not listed here
behaves the way upstream Swiftfin does. The list is meant to shrink: general fixes go
upstream as PRs, and an entry comes off once upstream has it.

Two things shape the list:

- **tvOS only.** Upstream splits effort across iOS and tvOS, and the big screen tends to
  come second. Several entries exist because a feature shipped for iOS and never got a
  tvOS entry point. The iOS target stays in the project so upstream merges stay clean.
- **VLC first.** VLC is the default player. Upstream's Native and MPV players are left in
  rather than stripped, but the player fixes below are only built and verified against VLC.

---

## Playback

**Up next card at the end of an episode.** Thirty seconds before the end, a card slides in
with the next episode and counts down into it. Play jumps straight there; Menu dismisses it
and lets the episode finish and exit instead. Upstream advances silently at end of file with
no UI at all.

The countdown drives the advance itself rather than waiting on the player's ended event —
VLC sends that early, and when the reported position never quite reaches runtime it doesn't
arrive at all.

**Skip intro and next episode pills.** A pill in the bottom corner offers a jump, taken with
select or play. During an intro the server has tagged it seeks to the end of that segment;
once the credits roll and something is queued it becomes Next Episode. Segments come from the
server's Media Segments API (Jellyfin 10.10+ with a segments plugin), and with no tagged outro
the credits window falls back to the last two minutes so the pill still works without the
plugin. The up next card suppresses the pill rather than stacking with it — both offer the
same jump. Window logic lives in `VideoPlayerSkipAction.resolve` and is deliberately free of
view state so it can be tested directly.

**Reliable episode transitions.** Upstream's end-of-item handler reads the current item and
the queue's next item *after* it may already have changed, so autoplay could stop instead of
advancing, or advance to the wrong episode. Reefy captures both up front, ignores an ended
event whose item no longer matches what's playing, ignores ended for live streams, and adds
a one-way stopping latch so exiting the player beats a late autoplay.

**Subtitle choice remembered per series.** Turning subs on or off carries to the next episode
and to future viewings, stored per user against the series id and matched by *language* —
stream indexes shift between episodes of the same show, so index matching doesn't survive an
episode change. Gated on the "Remember track selection" toggle that 1.5 added to settings but
never actually read. Preferred language and the server default still apply underneath.

**Menu doesn't drop you out of the app.** When the player overlay hides, every control goes
transparent and nothing in the container wants focus. Focus escapes, the Menu press never
reaches the player's handler, and tvOS treats it as unhandled — suspending the app to the
Home screen. An invisible focus anchor keeps the press inside the player. The anchor only
accepts focus while the overlay is hidden. It sits right under the timeline, so otherwise a down
press lands on it and the controls look frozen.

**Toolbar edits don't disable autoplay.** Upstream #1888 wires the bar/menu button pickers to
write `enableNextEpisodeAutoPlay` on the Jellyfin account, so removing the AutoPlay button
from the toolbar silently turned autoplay off server-wide and undid the toggle in settings.
The settings toggle is now the only thing that writes that flag.

**Episode name and year in the overlay title.** The subtitle carries season/episode, episode
name, and year, dropping whichever parts are missing. Movies pick up a year where they had no
subtitle at all.

**VLC subtitles in the tvOS caption style.** Once the style in Settings → Accessibility →
Subtitles & Captioning is customized, VLC draws subtitles with its font, colors, background,
edges, and size. On Default, VLC keeps its own look. Upstream's MPV player gets the style by
drawing the text itself. VLC can't do that, because libVLC 4 has no way to hand out cue text.
So the style goes onto libVLC's own renderer instead (`VLCCaptionStyle`). That only works on
the libVLC instance: the `:freetype-*` media options upstream sets for its font and color
settings are ignored, which is an upstream bug worth a PR. A style change applies the next
time the player opens. It's close to Apple's look, not identical: one box behind the text
instead of a separate window, raised and depressed edges drawn as shadows, and libVLC's own
font when the style uses the system font. CEA-608 captions keep their own text color and size.

**AVPlayer turns captions on for Closed Captions + SDH.** Upstream switches off AVPlayer's
automatic media selection, so the accessibility setting did nothing, and broadcast CEA-608 on
Live TV (which isn't a Jellyfin stream) couldn't be reached from the subtitle menu at all.
With the setting on and no subtitle picked, Reefy selects the captions itself
(`AVMediaPlayerProxy+SystemCaptions`). `AVPlayerLayer` draws them itself, not Swiftfin's overlay.

---

## Home

**Home rows refresh after playback.** Nothing in upstream's player tells the rest of the app
that playback stopped, so Next Up and Continue Watching keep showing the episode you just
finished. Reefy awaits the stop report, re-reads the item, then posts the user-data change the
refresh machinery is already listening for. The await matters — posting first races the server
and reads back the pre-playback state.

Upstream has the same fix in review as part of its live socket updates (Swiftfin #2265). This
comes off once that lands.

---

## Interface

**Coral accent by default** (`#FF7F50`, sampled off the jellyfish in the app icon), replacing
upstream's hardcoded purple wherever it's baked in — the accent defaults, sign-in buttons, and
the played tint. The color picker's Jellyfin option stays purple since that's what it names.

**Reefy identity** — bundle id, display name, app icon, top shelf art, and logo throughout
settings, about, and login. Deep links answer `reefy://` and the generic `jellyfin://`, but not
`swiftfin://`, so links meant for official Swiftfin still go to it when both are installed.

---

## Correctness

**Per-user device id.** Signing in as a second user invalidated the first user's token, so
everything 401'd after a switch. Reefy generates a device id per sign-in and persists it in
the keychain beside the access token. Quick Connect uses the same client to initiate and
redeem, since the secret is redeemed against the device that started the exchange. Users
stored without one fall back to the legacy derived id. (Reefy #57)

**Release year off by one.** `premiereDateYear` used the format `YYYY` — the *week*-based
year — so anything airing in the days either side of New Year could report the wrong year
everywhere a release year is shown. Which days flip depends on the locale's week rules (US
pushes late December forward, ISO locales also pull early January back). `yyyy` is the
calendar year.

**App Store builds strip arm64e.** Upstream's MPV player (#2274) pulls in MPVUI, whose tvOS
`Libmpv.xcframework` ships arm64 *and* arm64e. App Store Connect rejects arm64e in third-party
apps, so the 2.1.0 upload bounced. `Scripts/StripArm64e.sh` runs as the last tvOS build phase,
removes the slice, and re-signs the framework. Upstream hasn't shipped a build with MPV yet, so
it hasn't hit this; comes off once MPVUI drops arm64e or Swiftfin handles it.

**tvOS alternate icons declared by hand.** Upstream's tvOS icon picker (#2340) lists the
alternates through `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`, and the asset catalog
compiler writes `CFBundleAlternateIcons` in the iOS shape, a dictionary of dictionaries. tvOS
wants a plain array of names, and App Store Connect rejected the first 2.1.1 upload with
"Missing Image Asset". Those build settings are off for the tvOS target and the list sits in its
`Info.plist`. Upstream has only run the picker in Debug; comes off once Xcode writes the tvOS
shape or Swiftfin fixes it.

---

## Not yet carried forward

These shipped in the pre-rebase Reefy line (frozen at `reefy-1.4.3-final`) and have not been
ported to the current base. Listed so they don't get quietly forgotten.

| | Notes |
|---|---|
| Audio output mode setting | System Default / Auto / Stereo / Passthrough. Reefy #19, #55. Still advertised in `CHANGELOG.md`. |
| Pre-play subtitle picker | A captions menu next to Play on the item screen. Reefy #5. Upstream #2202 moved track and version selection into the item page's action buttons, which may cover this — check on device before porting anything. |
| Menu at tab roots returns to Home | Separate from the in-player fix above. |
| Menu inside pushed settings screens | Focused menu rows eat the press and the app suspends. |
| Test target | `Swiftfin tvOS Tests/` was deleted by the rebase; roughly 480 lines of player and subtitle tests went with it. Restoring it needs `project.pbxproj` work. |
| Home refresh on foreground | The `didRequestGlobalRefresh` key still exists with nothing posting or observing it. Upstream #2265 wires it up if it lands. |

### Replaced by upstream

Dropped in the 2026-09 merge because upstream shipped its own:

| Reefy had | Upstream now |
|---|---|
| tvOS filter bar | tvOS Filters (#2321) |
| Icon-only tab bar | Sidebar tab bar (#2107), with a Sidebar / Centered setting (#2256) |
| Orange position marker on the transport tick | The slider it lived on was rewritten (#2293) and no longer has a tick |

Deliberately **not** restored: auto-marking an episode played at 95%. It cleared the Next Up
row a little faster, but quitting at 95% marked the episode watched when you hadn't finished
it. The server decides watch state now.

---

## Verifying player changes

The player work above is focus- and timing-sensitive, and the tvOS simulator does not
reproduce either faithfully. Build to a real Apple TV before trusting any of it.
