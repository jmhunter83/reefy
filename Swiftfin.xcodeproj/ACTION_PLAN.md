# Reefy Rebranding - Action Plan

## 🎯 Current Status

I've analyzed your codebase and found:
- ✅ Some strings already reference "Reefy" (lines 620, 1387 in Strings.swift)
- ✅ Code properly uses "Swiftfin" internally (good for merging!)
- 📝 Need to complete user-facing rebranding

---

## 📋 Your Action Items

### Phase 1: Xcode Project (Do First)
**See `GETTING_STARTED.md` for detailed steps**

1. [ ] Open project in Xcode
2. [ ] Update Bundle Identifier for each target
3. [ ] Update Product Name to "Reefy"
4. [ ] Rename schemes (optional)

---

### Phase 2: Info.plist Files (I'll Help)
After Phase 1, tell me and I'll help find and update:
- CFBundleDisplayName
- CFBundleName
- URL schemes

---

### Phase 3: Localized Strings (I'll Help)
Your `Strings.swift` is auto-generated. We need to find the source `.strings` files.

**Already contains "Reefy"**:
- ✅ Line 620: "Checks for important announcements from Reefy developers..."
- ✅ Line 1387: "Reefy requires Jellyfin version..."

**Need to verify** all other user-visible strings are properly branded.

---

### Phase 4: Assets (You'll Do)
1. [ ] Replace app icons
2. [ ] Update launch screen
3. [ ] Replace splash screens
4. [ ] Update any logo images

---

### Phase 5: Documentation (I'll Help)
1. [ ] Create new README.md
2. [ ] Add acknowledgment to Swiftfin
3. [ ] Update any developer docs

---

### Phase 6: Testing (You'll Do)
1. [ ] Build succeeds
2. [ ] App shows "Reefy" name
3. [ ] Correct icon displays
4. [ ] All features work
5. [ ] Settings show correct name

---

## 🤔 Questions Before We Continue

1. **Have you already updated some strings?**
   - I see "Reefy" already in the strings file
   - Did you start rebranding already?

2. **What bundle identifier do you want to use?**
   - Examples: `com.yourname.reefy`, `io.reefy.app`
   - This is important for next steps

3. **Do you have new app icons ready?**
   - If not, I can give you some design suggestions
   - Or temporary placeholder ideas

---

## 🚀 Let's Start!

**Option A: Manual Xcode Changes First**
→ Follow `GETTING_STARTED.md` to update Xcode settings
→ Come back when done and I'll help with the rest

**Option B: Let Me Help Find Files First**
→ I'll locate all Info.plist files and localization files
→ You can see what needs updating before Xcode changes

**Option C: Tell Me What You've Already Done**
→ If you've already started some changes
→ I'll help complete the rest

Which would you like to do? Just tell me and we'll continue! 🎯
