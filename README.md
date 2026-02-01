<div align="center">

# Reefy

**A tvOS-focused Jellyfin client**

<img src="https://img.shields.io/badge/tvOS-17+-blue"/>
<img src="https://img.shields.io/badge/Jellyfin-10.11-9962be"/>
<img src="https://img.shields.io/badge/App%20Store-Available-blue"/>
<img src="https://img.shields.io/badge/Countries-175-brightgreen"/>

</div>

> **Note:** This project has been officially renamed to **Reefy** on GitHub. It is an independent project, not affiliated with or endorsed by [Jellyfin](https://jellyfin.org) or [Swiftfin](https://github.com/jellyfin/swiftfin). It is a fork of Swiftfin, developed separately with a focus on Apple TV.

---

## About

**Reefy** is a native Jellyfin media client built exclusively for Apple TV. It uses VLC for direct playback and is designed to feel native on tvOS.

I forked Swiftfin to build a **modern, fully-functional client that keeps up with tvOS and Jellyfin**. The goal is simple: access your videos with current features and a polished experience.

This project focuses purely on the tvOS experience — no iOS, just Apple TV.

---

## Features

- **tvOS 18 Liquid Glass** — Native glass transport bar with tvOS 17 fallback
- **Redesigned playback controls** — Clean layout in bottom 15% of screen
- **Native progress slider** — Pill-shaped, 8px height
- **Full-screen item views** — Proper detail views, not cards
- **Improved focus states** — Smooth scale animations on button focus
- **tvOS 18+ compatibility** — Sheet presentation and TextField fixes

---

## Coming Soon

### Audio Normalization (ReplayGain)

Volume normalization for music playback is in development. No more adjusting volume when switching between quiet and loud tracks — Reefy will automatically balance audio levels using ReplayGain metadata from your Jellyfin server.

**Features:**
- Track and Album normalization modes
- Adjustable pre-amp (+/- 12 dB)
- Clipping prevention
- Works with Jellyfin's Audio Normalization scheduled task

*Requires Jellyfin Server 10.9+ with Audio Normalization task enabled.*

See [Audio Normalization Documentation](Documentation/features/audio-normalization.md) for setup details.

---

## Get Reefy

### App Store (Recommended)

Reefy is available on the Apple App Store in 175 countries.

**How to install:**
1. On your Apple TV, open the App Store
2. Search for "Reefy Media Player"
3. Purchase and download ($8.99 USD one-time purchase)

**Requirements:**
- Apple TV (tvOS 17+ recommended, tvOS 18+ for Liquid Glass effects)
- Jellyfin media server (10.11+ recommended)
- $8.99 USD (one-time purchase, no subscriptions)

*Note: tvOS apps can only be purchased directly on Apple TV. Search for "Reefy Media Player" in the tvOS App Store.*

### TestFlight (Bleeding Edge)

Want to try new features first and help shape the future of Reefy? Join the TestFlight beta!

**Join the beta:** [https://testflight.apple.com/join/nVGxSegz](https://testflight.apple.com/join/nVGxSegz)

Beta testers get early access to bleeding-edge features, can provide feedback, and directly influence the product roadmap. Your input helps make Reefy better for everyone.

**Please consider purchasing the App Store version to support ongoing development**, even if you use the TestFlight build day-to-day.

### Build from Source (Developers)

Developers can build Reefy from source for free under the MPL 2.0 license.

See [Documentation/contributing.md](Documentation/contributing.md) for build instructions.

---

## Why Reefy?

I forked Swiftfin with a simple goal: **get something modern, fully working, and up to par with tvOS**. I wanted to access my Jellyfin videos without dealing with outdated apps, broken navigation, or missing features.

### What makes Reefy different

- **Modern tvOS experience** — Native focus states, smooth navigation, tvOS 18 Liquid Glass effects
- **Redesigned playback controls** — Clean transport bar that feels like Apple's own video players
- **Fixed what was broken** — Resolved memory leaks, navigation traps, and stability issues
- **VLC-based playback** — Wide codec support for all your media files
- **tvOS-native UI** — Full-screen detail views, native progress slider, proper remote interaction
- **Active development** — Regular updates and bug fixes

### Pricing & Source Code

- **App Store**: $8.99 USD one-time purchase
- **Source Code**: Free and open source (MPL 2.0 license)

The App Store price covers Apple's $99/year developer fee and commits me to ongoing support and updates. The source code is freely available for anyone who wants to build it themselves or contribute improvements.

---

## Acknowledgments

Built on the work of:
- [Jellyfin](https://jellyfin.org) — The free software media system
- [Swiftfin](https://github.com/jellyfin/swiftfin) — The original Swift client this project was forked from

---

## License

This project is licensed under the [Mozilla Public License 2.0](LICENSE.md).
