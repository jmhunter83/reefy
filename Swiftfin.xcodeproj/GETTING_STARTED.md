# Reefy Rebranding - Getting Started

## What We Found

Your project uses `.xcconfig` files and inherited build settings, which means most configuration is in the Xcode project file itself (which I can't directly edit). Here's what you need to do:

---

## Step 1: Xcode Project Settings (Manual)

### Open Your Project in Xcode

1. **Open** `Swiftfin.xcodeproj` (or your main project file)

### Update Bundle Identifier

2. **Select** your project in the navigator
3. **Select** each target (e.g., Swiftfin iOS, Swiftfin tvOS)
4. **Go to** General tab
5. **Change** Bundle Identifier:
   - From: `org.jellyfin.swiftfin` (or similar)
   - To: `com.yourname.reefy` (choose your own identifier)

   Example:
   - `com.reefy.app`
   - `com.yourdomain.reefy`
   - `io.reefy.ios`

   ⚠️ **Important**: Use the same base identifier for all targets, just change the suffix:
   - iOS: `com.yourname.reefy`
   - tvOS: `com.yourname.reefy.tvos`
   - Extensions: `com.yourname.reefy.extension-name`

### Update Product Name

6. **Go to** Build Settings tab
7. **Search** for "Product Name"
8. **Change** `PRODUCT_NAME` from `Swiftfin` to `Reefy`

### Rename Schemes (Optional but Recommended)

9. **Go to** Product → Scheme → Manage Schemes
10. **Double-click** each scheme to rename:
    - `Swiftfin (iOS)` → `Reefy (iOS)`
    - `Swiftfin (tvOS)` → `Reefy (tvOS)`
    - Any other schemes

---

## Step 2: Update Info.plist Files

I'll help you update these next! But first, let's find them.

### Find Your Info.plist Files

In Terminal, run:
```bash
find . -name "Info.plist" -not -path "*/Build/*" -not -path "*/.build/*"
```

Or in Xcode:
1. Use Cmd+Shift+O (Open Quickly)
2. Type "Info.plist"
3. Open each one

### What to Change in Each Info.plist

Look for and update these keys:

```xml
<key>CFBundleDisplayName</key>
<string>Reefy</string>

<key>CFBundleName</key>
<string>Reefy</string>
```

**Optional** - If you have URL schemes, update them:
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>reefy</string>
</array>
```

---

## Step 3: App Icons

### Update App Icons

1. **Open** your asset catalog (usually `Assets.xcassets`)
2. **Find** `AppIcon` asset
3. **Replace** all sizes with your Reefy icon
   - Keep the asset named `AppIcon` (don't rename it)
   - Make sure to fill all required sizes

### Design Your Icon

If you haven't designed one yet, here are some ideas for Reefy:
- 🐠 Reef theme (coral, fish, ocean)
- 🎬 Media theme (play button, film reel)
- Combination of both

Tools to create icons:
- Figma (free)
- Sketch
- Affinity Designer
- Even Canva

Or hire a designer on Fiverr/Upwork for ~$20-50.

---

## Step 4: Launch Screen

1. **Find** `LaunchScreen.storyboard` or your launch screen asset
2. **Update** any "Swiftfin" text or logos
3. **Replace** with "Reefy" branding

---

## Next Steps After Manual Changes

Once you've completed the above Xcode changes, let me know and I'll help you:

1. ✅ Find and update user-visible strings
2. ✅ Update README and documentation
3. ✅ Create a proper attribution to Swiftfin
4. ✅ Set up any build configurations
5. ✅ Test everything works

---

## Quick Verification

After making changes, verify:

```bash
# Build the project
cmd+B in Xcode

# Check the app name shows as "Reefy"
# (You'll see this when you run on simulator/device)
```

---

## Questions?

**Q: What bundle identifier should I use?**
A: Use your own domain in reverse. Examples:
- Personal: `com.yourname.reefy`
- Company: `com.yourcompany.reefy`
- Creative: `io.reefy.app` or `app.reefy.ios`

**Q: Do I need to change the Xcode project name?**
A: Not necessary. You can keep `Swiftfin.xcodeproj` - the product name and bundle ID are what matter.

**Q: What about the Apple Developer account?**
A: You'll need to:
- Register your new bundle identifier in your Apple Developer account
- Create new App Store Connect entry (separate from Swiftfin)
- Generate provisioning profiles for your new bundle ID

---

**Ready?** Make these Xcode changes, then come back and let me know! 🚀
