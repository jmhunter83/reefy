# Reefy - User-Facing Rebranding Guide

This guide covers rebranding Swiftfin to **Reefy** for user-facing elements only, while keeping internal code unchanged for easy upstream merging.

## Philosophy

**Keep code internal, rebrand user-facing elements only.**

- ✅ **DO**: Change what users see (app name, icons, bundle ID)
- ❌ **DON'T**: Change internal code (class names, method names, file names)

This approach allows you to:
- Easily merge upstream Swiftfin updates
- Maintain code compatibility
- Keep git diffs clean and focused
- Preserve attribution to original project

---

## 1. Xcode Project Configuration

### Bundle Identifier
Change in your Xcode project settings or `.xcconfig` files:

**From**: `org.jellyfin.swiftfin` (or similar)  
**To**: `com.yourname.reefy` (or your preferred identifier)

**Where to change**:
- Target settings → General → Bundle Identifier
- Or in your `.xcconfig` files

### Product Name
In your Xcode project build settings:

```
PRODUCT_NAME = Reefy
```

This changes the binary name without touching source code.

---

## 2. Info.plist Changes

Update your `Info.plist` file(s):

```xml
<key>CFBundleDisplayName</key>
<string>Reefy</string>

<key>CFBundleName</key>
<string>Reefy</string>

<!-- Update URL schemes if applicable -->
<key>CFBundleURLSchemes</key>
<array>
    <string>reefy</string>
</array>
```

**Important**: Don't change these in code - only in Info.plist!

---

## 3. App Icons & Assets

### App Icon
Replace the app icon in your asset catalog:

1. Open `Assets.xcassets` (or your asset catalog)
2. Find `AppIcon`
3. Replace all icon sizes with your Reefy branding
4. Keep the asset name as `AppIcon` (don't rename it)

### Launch Screen
Update launch screen assets:

1. Update `LaunchScreen.storyboard` or `Launch Screen.storyboard`
2. Replace any "Swiftfin" logos with "Reefy" branding
3. Update colors/styling to match your brand

### Other Assets
Replace in asset catalog:
- Splash screens
- About screen logos
- Tutorial/onboarding images
- Any images with "Swiftfin" branding

---

## 4. Scheme Names (Optional)

In Xcode, rename your schemes:

1. Go to Product → Scheme → Manage Schemes
2. Rename schemes:
   - `Swiftfin (iOS)` → `Reefy (iOS)`
   - `Swiftfin (tvOS)` → `Reefy (tvOS)`
   - etc.

**Note**: This is optional and only affects your development experience.

---

## 5. User-Facing Strings

Update localized strings in your `Localizable.strings` or similar files:

### About Screen
Look for strings like:
```swift
"About Swiftfin" → "About Reefy"
"Swiftfin is a client for Jellyfin" → "Reefy is a client for Jellyfin"
```

### Settings
Update any user-visible references:
```swift
"Swiftfin Version" → "Reefy Version"
```

### Alerts/Messages
Search for user-facing strings that mention "Swiftfin"

**How to find them**:
```bash
# Search in strings files
find . -name "*.strings" -exec grep -i "swiftfin" {} +

# Search in SwiftUI views (only change user-facing Text)
grep -r "Text(\".*[Ss]wiftfin" --include="*.swift"
```

---

## 6. Documentation Files

### README.md
Create or update `README.md`:

```markdown
# Reefy

Reefy is a modern client for Jellyfin media servers, based on the excellent Swiftfin project.

## About

This is a fork of [Swiftfin](https://github.com/jellyfin/swiftfin) with [your custom features/changes].

## Acknowledgments

Built on top of Swiftfin by the Jellyfin community.
```

### LICENSE
Keep the original MPL 2.0 license. Optionally add a note:

```
This project is a fork of Swiftfin by Jellyfin contributors.
Original project: https://github.com/jellyfin/swiftfin
```

### Other Docs
Update these files if they exist:
- `CONTRIBUTING.md`
- `CHANGELOG.md` (start fresh or continue)
- `CREDITS.md`

---

## 7. App Store / Distribution

### App Store Connect
- **App Name**: Reefy
- **Subtitle**: Your custom subtitle
- **Description**: Mention it's based on Swiftfin if you want
- **Screenshots**: New screenshots without "Swiftfin" UI
- **Keywords**: Include relevant keywords

### TestFlight
- **Beta App Name**: Reefy (Beta)
- **Beta Description**: Updated description

### Privacy Policy
- Update any URLs that reference your project
- Update app name throughout

---

## 8. Build & CI/CD Configuration

### Fastlane
If using Fastlane, update `Fastfile`:

```ruby
app_identifier("com.yourname.reefy")
app_name("Reefy")
```

### GitHub Actions / CI
Update workflow files (`.github/workflows/*.yml`):

```yaml
name: Reefy CI

env:
  APP_NAME: "Reefy"
  BUNDLE_ID: "com.yourname.reefy"
```

### Build Scripts
Update any custom build scripts that reference:
- App names
- Bundle identifiers
- Output paths

---

## 9. What NOT to Change

❌ **Do NOT change these** (keep as Swiftfin):

### Source Code
```swift
// Keep these as-is
struct SwiftfinApp: App { }
enum SwiftfinStore { }
class SwiftfinImagePipelineDelegate { }
extension ImagePipeline.Swiftfin { }
Logger.swiftfin()
```

### File Names
Keep original names:
- `SwiftfinApp.swift`
- `SwiftfinStore.swift`
- `SwiftfinDefaults.swift`
- etc.

### Comments
Keep code comments as-is:
```swift
// Keep existing comments
// TODO: fix swiftfin player bug
```

### Internal Strings
Non-user-visible strings:
```swift
// Keep these
UserDefaults(suiteName: "swiftfinApp")
Logger(label: "org.jellyfin.swiftfin")
"swiftfin-cache-key"
```

---

## 10. Testing Checklist

After rebranding, test:

- [ ] App launches with correct name
- [ ] App icon shows correctly
- [ ] About screen shows "Reefy"
- [ ] Settings show "Reefy"
- [ ] Bundle identifier is correct
- [ ] Deep links work (if changed)
- [ ] App Store build works
- [ ] Existing user data migrates correctly
- [ ] All functionality still works

---

## 11. Maintaining Upstream Compatibility

### Merging Upstream Changes

```bash
# Add upstream remote
git remote add upstream https://github.com/jellyfin/swiftfin.git

# Fetch latest changes
git fetch upstream

# Merge main branch
git merge upstream/main

# Resolve conflicts (should be minimal with this approach)
```

### Typical Conflicts
With user-facing rebranding only, you should only get conflicts in:
- Info.plist (easy to resolve)
- Asset catalogs (keep your Reefy assets)
- README.md (keep your fork's README)
- Build configurations (keep your bundle ID)

Code conflicts should be rare or non-existent!

---

## 12. Optional: Version Customization

You might want to customize versioning to differentiate from upstream:

### Option A: Keep upstream version + suffix
```
Upstream: 1.2.0
Yours: 1.2.0-reefy
```

### Option B: Independent versioning
```
Start at: 1.0.0 (Reefy)
```

Update in:
- Xcode project settings
- `CFBundleShortVersionString`
- Build number (`CFBundleVersion`)

---

## 13. Analytics & Services (if applicable)

Update service configurations:

### Crash Reporting
- Update app identifier in Sentry/Crashlytics/etc.
- Update DSNs and API keys

### Analytics
- Update GA/Mixpanel/etc. project IDs
- Update event names if you want to differentiate

### Push Notifications
- New APNS certificate for new bundle ID
- Update backend services

---

## Quick Reference Commands

```bash
# Find user-facing "Swiftfin" text in strings files
find . -name "*.strings" -o -name "*.stringsdict" | xargs grep -i "swiftfin"

# Find Text() with Swiftfin in SwiftUI views
grep -r 'Text(".*[Ss]wiftfin' --include="*.swift" .

# Check Info.plist files
find . -name "Info.plist" -exec grep -l "swiftfin" {} +

# Search for bundle identifiers
grep -r "org.jellyfin.swiftfin" --include="*.plist" --include="*.xcconfig" .
```

---

## Summary

This approach gives you:
- ✅ Clean user-facing "Reefy" branding
- ✅ Easy upstream merging
- ✅ Minimal git conflicts
- ✅ Proper attribution to original project
- ✅ Maintainable fork

The key is: **Change what users see, not what computers see.**

---

## Need Help?

Common questions:

**Q: Can I change some class names for my custom features?**  
A: Yes! For *new* code you add, use Reefy naming. For upstream code, keep Swiftfin naming.

**Q: What about comments in code?**  
A: Leave them as-is. They're not user-facing and don't affect merging.

**Q: Should I keep Jellyfin in the bundle ID?**  
A: No - use your own identifier like `com.yourname.reefy` to avoid conflicts.

**Q: Can I rename the repository?**  
A: Yes! Repository name doesn't affect code merging. Call it `reefy` or `reefy-ios`.

---

Good luck with your Reefy fork! 🐠
