# App Store Connect copy — 2.2.0

Paste into the 2.2.0 submission. Limits in parens.

Still requires tvOS 26.

## Subtitle (30)

Unchanged.

```
Jellyfin for your Apple TV
```

## Promotional text (170)

```
Subtitles in VLC follow your Apple TV caption style, and AVPlayer turns captions on by itself when Closed Captions + SDH is on.
```

## What's New (4000)

```
Captions, mostly.

- VLC draws subtitles in your Apple TV caption style now. Set one up in Settings > Accessibility > Subtitles & Captioning > Style and VLC picks up the font, colors, background, edges and size. Leave it on Default and VLC looks the same as before. If you change the style, it shows up the next time you start something
- AVPlayer turns captions on by itself when Closed Captions + SDH is on, Live TV captions included. Before, that setting did nothing in AVPlayer
```

## TestFlight — What to Test (4000)

```
Still needs tvOS 26.

This one's all captions:
- Settings > Accessibility > Subtitles & Captioning > Style. Pick something you'll notice, like Large Text or a custom style with yellow text. Play something in VLC with subtitles on. They should look like your style
- Put the style back to Default. VLC subs should look the way they did in 2.1.1
- If you use AVPlayer: turn on Closed Captions + SDH in that same screen, then play something with captions, or a Live TV channel. Captions should come on without opening the subtitle menu
- Live TV captions in VLC pick up your font and background, but not your text size or color. That's a VLC limit, so AVPlayer is the better pick for Live TV captions

If something breaks, send me your Apple TV model, tvOS version, and Jellyfin server version.
```

## Keywords (100)

Added `captions`.

```
jellyfin,server,stream,home,theater,movies,shows,vlc,library,subtitles,4k,hdr,dolby,captions
```
