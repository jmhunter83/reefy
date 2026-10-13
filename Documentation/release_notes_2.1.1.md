# App Store Connect copy — 2.1.1

Paste into the 2.1.1 submission. Limits in parens.

Still requires tvOS 26.

## Subtitle (30)

Unchanged.

```
Jellyfin for your Apple TV
```

## Promotional text (170)

```
Pick your own app icon, and the player controls stop getting stuck on screen.
```

## What's New (4000)

```
A small one, mostly a fix.

- The player controls could get stuck on screen. Touch the remote, press down, and you'd land on nothing: controls up, nothing selected, and they'd never hide on their own. Fixed, and down goes to Chapters again like it should
- New app icon picker in Settings > Customize > App Icon. Swiftfin's colors, with the Reefy icon still the default
- More of Swiftfin's player work under the hood, and settings rows don't get clipped anymore
```

## TestFlight — What to Test (4000)

```
Still needs tvOS 26.

Mostly a player fix, so that's where I'd look:
- Start something, let the controls hide, then touch the remote and press down. You should land on Chapters (or whatever's under the timeline), and the controls should hide on their own again after a few seconds
- Mash Menu during playback. You should never land on the Apple TV home screen
- Settings > Customize > App Icon. Pick a color, check your home screen, then switch back to the default

If something breaks, send me your Apple TV model, tvOS version, and Jellyfin server version.
```

## Keywords (100)

Unchanged.

```
jellyfin,server,stream,home,theater,movies,shows,vlc,library,subtitles,4k,hdr,dolby
```
