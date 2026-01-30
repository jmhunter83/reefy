# Frequently Asked Questions

## General

### What is Reefy?

Reefy is a native tvOS client for Jellyfin media servers. It's a fork of Swiftfin focused exclusively on Apple TV with modern tvOS features like Liquid Glass effects.

### Is Reefy affiliated with Jellyfin or Swiftfin?

No. Reefy is an independent fork of Swiftfin, developed separately. It is not affiliated with or endorsed by the Jellyfin project or the Swiftfin team.

### What platforms does Reefy support?

tvOS only (Apple TV). Reefy does not support iOS, iPadOS, or macOS.

---

## Pricing & Source Code

### Why does Reefy cost $8.99 on the App Store?

The $8.99 covers:
- Apple's $99/year developer program fee
- Ongoing development, support, and updates
- App Store distribution and hosting

### Is the source code free?

Yes. Reefy is open source under the MPL 2.0 license. The full source code is available at [github.com/jmhunter83/reefy](https://github.com/jmhunter83/reefy).

### Can I build Reefy for free?

Yes. Developers can clone the repository and build Reefy themselves using Xcode. See [INSTALLATION.md](INSTALLATION.md) for instructions.

---

## Technical

### What tvOS version do I need?

- **Minimum**: tvOS 17
- **Recommended**: tvOS 18+ (for Liquid Glass effects)

### Does Reefy work with all Jellyfin servers?

Reefy is designed for Jellyfin 10.11+. Older versions may work but are not officially supported.

### What media formats does Reefy support?

Reefy uses VLC for playback, which supports a wide range of codecs including:
- H.264, H.265/HEVC
- VP9, AV1
- MP4, MKV, AVI containers
- AAC, AC3, DTS audio

See VLCKit documentation for the complete codec list.

### Does Reefy support HDR?

Yes. Reefy supports HDR10 and Dolby Vision content when your Apple TV and TV support these formats.

---

## Troubleshooting

### I'm experiencing intermittent audio (buffering/stuttering) with surround sound content

**Symptom:** Audio rapidly cuts in and out, or you see frequent buffering, specifically with 5.1 surround sound content (AC3/Dolby Digital or EAC3/Dolby Digital Plus).

**Cause:** This occurs when your Apple TV outputs to stereo (TV speakers or stereo soundbar) but receives AC3/EAC3 5.1 audio that it must downmix. VLC's software decoder can struggle with this, causing audio dropouts.

**Fix:** Enable "Most Compatible" playback mode to force server-side transcoding:

1. Open Reefy settings
2. Navigate to: **Video Player → Playback Compatibility**
3. Change from "Auto" to **"Most Compatible"**
4. Retry playback

This tells your Jellyfin server to transcode AC3/EAC3 5.1 audio to AAC stereo before sending it to your Apple TV, which VLC handles reliably.

**Note:** If you have a proper surround sound receiver connected via eARC/ARC and use audio passthrough, you likely won't experience this issue.

---

## App Store

### Which countries is Reefy available in?

Reefy is available in 175 countries on the Apple App Store, covering most global regions.

### Can I purchase Reefy from my iPhone?

No. tvOS apps must be purchased directly on your Apple TV device. You can browse the app on your iPhone/iPad, but the purchase must be completed on Apple TV.

### Is there a subscription?

No. Reefy is a one-time purchase of $8.99 USD with no subscriptions or in-app purchases.

### Do I need to pay again for updates?

No. Once purchased, all future updates are free.

---

## Fork Relationship

### Why fork Swiftfin instead of contributing?

Swiftfin tvOS development has been paused with no TestFlight available and no committed timeline. Reefy was created to serve tvOS users who needed a working app immediately.

Long-term, focusing exclusively on tvOS allows for platform-specific improvements that are more difficult in a multi-platform codebase.

### Will Reefy merge back into Swiftfin?

No plans for that. Reefy is a separate project with independent development. However, improvements from Reefy may be contributed back to Swiftfin if appropriate.

### What's different from Swiftfin?

- tvOS-exclusive focus (no iOS/iPadOS)
- tvOS 18 Liquid Glass transport bar
- Redesigned playback controls
- Fixed navigation bugs and memory leaks
- Active development and App Store distribution

---

## Support

### How do I report a bug?

File an issue on GitHub: [github.com/jmhunter83/reefy/issues](https://github.com/jmhunter83/reefy/issues)

Use the bug report template and include:
- Reefy version/build number
- Apple TV model and tvOS version
- Steps to reproduce
- Expected vs. actual behavior

### How do I request a feature?

Create a feature request on GitHub Discussions: [github.com/jmhunter83/reefy/discussions](https://github.com/jmhunter83/reefy/discussions)

---

## Beta Program

### Was there a beta program?

Yes. Reefy ran a public beta via TestFlight from December 2025 through January 17, 2026. The beta program closed when Reefy launched on the App Store.

### Can I still join the beta?

The public beta program is closed. Beta testers have been migrated to the App Store version.

### Will there be future betas?

Possibly, for major feature testing. Future beta programs will be announced on GitHub.
