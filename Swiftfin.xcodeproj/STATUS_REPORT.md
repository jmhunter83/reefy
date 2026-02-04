# Reefy Rebranding - Current Status Report

## ✅ GOOD NEWS: User-Facing Strings Already Rebranded!

I found **21 references to "Reefy"** already in your localized strings! 🎉

### Strings Already Using "Reefy":

1. ✅ Custom device profile descriptions (lines 434, 436)
2. ✅ Remote notices description (line 620)
3. ✅ Password change warning (line 1092)
4. ✅ Player description (line 1136)
5. ✅ Reset settings description (line 1282)
6. ✅ Server version warning (line 1387)
7. ✅ Welcome screen description (line 1428)
8. ✅ Sign out background description (line 1444)
9. ✅ Face ID authentication message (line 1626)
10. And more!

**Zero "Swiftfin" references found in user strings** ✨

---

## 📋 What Still Needs To Be Done

### 1. Xcode Project Configuration ⚠️ (CRITICAL)

You MUST update these in Xcode:

- [ ] **Bundle Identifier**: `org.jellyfin.swiftfin` → `com.yourname.reefy`
  - This is the unique identifier for your app
  - Required to publish to App Store
  - Different from upstream Swiftfin

- [ ] **Product Name**: Update build settings to `Reefy`
  - This sets the binary name
  - Affects what users see in some places

- [ ] **Scheme Names**: (Optional) Rename for clarity
  - Makes development easier
  - Not critical for functionality

**📖 How to do this**: See `GETTING_STARTED.md`

---

### 2. Info.plist Files (Need to Find & Update)

Let me search for these next. They should contain:
- `CFBundleDisplayName` → Should be "Reefy"
- `CFBundleName` → Should be "Reefy"
- URL schemes (if any)

---

### 3. Assets (Visual Branding)

- [ ] App Icons - Replace with Reefy branding
- [ ] Launch Screen - Update graphics/text
- [ ] Splash Screens - Replace any logos
- [ ] In-app logo images

---

### 4. Documentation

- [ ] README.md - Create Reefy-specific README
- [ ] Acknowledgment to Swiftfin
- [ ] Update CONTRIBUTING.md (if exists)

---

### 5. Build Configuration

- [ ] Update any hardcoded bundle IDs in config files
- [ ] Update CI/CD if you use it
- [ ] Update fastlane if you use it

---

## 🔍 Next: Let Me Find Your Info.plist Files

I'll search for all Info.plist files now to see what needs updating there.

Then we'll check for any other configuration files.

---

## 💡 Summary

**Already Done** ✅:
- User-facing strings are branded as "Reefy"
- No "Swiftfin" in visible text
- Code internally still uses "Swiftfin" (perfect for merging!)

**Still TODO** ⚠️:
- Xcode project settings (bundle ID, product name)
- Info.plist updates
- App icons/assets
- Documentation

---

**You're ~50% done already!** The hard part (strings) is complete. Now just config and assets! 🎯
