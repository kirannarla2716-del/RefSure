# RefSure — Implementation Change Log
**Session date:** 2026-05-31  
**Scope:** Bug fixes + missing feature implementation (Phases 1–4)

---

## PHASE 1 — Bug Fixes

### Quick Tour / App Tour
**File:** `lib/screens/main_screens.dart`  
- Renamed "App Tour" label to **"Quick Tour"** pill badge  
- Added **page counter** (e.g. 1/4) and close (×) icon in the tour header  
- Replaced single "Got it" button with **Previous / Next / Got it** navigation row  
  - Previous: `TextButton.icon` with `arrow_back_ios`, calls `_pageCtrl.previousPage()`  
  - Next: `FilledButton.icon` with `arrow_forward_ios`, calls `_pageCtrl.nextPage()`  
  - Last slide: "Got it ✓" FilledButton that dismisses and marks tour seen  
- Animation: 250 ms `easeInOut` page transitions

### Total Apps / Working Changes
**File:** `lib/screens/main_screens.dart`  
- Renamed card title from "Your referrals" → **"My Applications"**  
- Made **each metric tile individually tappable** (wrapped in `GestureDetector` → `/applications`)  
- Renamed "Open" status label → **"In Progress"** (clearer meaning)  
- Moved card-level `onTap` to just the header row; added chevron icon

### Auto Job Fetch — Top 30 Active Jobs
**File:** `lib/services/firestore_service.dart`  
- Added `.limit(30)` to `watchActiveJobs()` Firestore query  
- Added `.limit(10)` to `watchHotJobs()` Firestore query  
- Fixed expired sample job deadlines (`2026-05-30` → `2026-08-30`)

---

## PHASE 2 — Remove Duplicate Module

### Remove Seekers Tab from Provider Nav
**File:** `lib/router.dart`  
- Removed `Seekers` `BottomNavigationBarItem` from `_providerItems` (was index 2)  
- Updated `_providerRoutes` from `['/', '/jobs', '/providers', '/messages', '/profile']` → `['/', '/jobs', '/messages', '/profile']`  
- Provider bottom nav now has 4 tabs: Dashboard · Jobs · Messages · Profile

---

## PHASE 3 — New Features

### Messages Module — Relevant Contacts Only
**File:** `lib/screens/feature_screens.dart`  
- `MessagesScreen` no longer shows all users from `prov.seekers` / `prov.providers`  
- **Seekers** see only providers of jobs they applied to (derived from `prov.myApplications.providerId`)  
- **Providers** see only seekers who applied to their jobs (derived from `prov.providerApplications.seekerId`)  
- Deduplication via `Set<String>` before mapping to `AppUser`  
- Empty state subtitle is role-specific

### Support Section in Profile
**Files:** `lib/core/constants/app_constants.dart`, `lib/screens/feature_screens.dart`  
- Added `AppConstants.supportEmail = 'support@refsure.app'`  
- Added `AppConstants.supportPhone = '+1 (800) 555-0100'`  
- Added `_SupportRow` helper widget (icon · label · value · chevron, tappable)  
- Added **Support `SectionCard`** in `ProfileScreen` above the Developer section  
  - Email Support row → shows SnackBar with email address  
  - Call Support row → shows SnackBar with phone number

### User Mode Banner
**File:** `lib/router.dart`  
- Persistent `Material` banner injected at the top of `_ShellScaffold` body (above all screens)  
- **Provider mode:** teal (`AppColors.primary`) background, "Referral Provider Mode" label, `business_center` icon  
- **Seeker mode:** purple (`#7C3AED`) background, "Referral Requester Mode" label, `person_search` icon  
- 11px semibold white text, 4px vertical padding, centered with icon

### Header Font Visibility
**File:** `lib/features/careers_portal/presentation/screens/careers_portal_screen.dart`  
- AppBar title "Open Roles" color: `AppColors.textPrimary` → **`Colors.white`**  
- Subtitle (company name) color: `AppColors.textHint` → **`Colors.white70`**

---

## PHASE 4 — Import Jobs Improvements

### Fetch More Jobs
**Files:** `lib/services/careers_portal_service.dart`, `lib/features/careers_portal/data/careers_portal_repository.dart`  
- Changed `filterLast30Days` default: `true` → **`false`** in both service and repository  
- Added two more slug variants to `_buildSlugs()`: underscore form (`goldman_sachs`) and first-two-words hyphenated (`goldman-sachs` for 3+ word names)

### Fix Imported Job Data (Skills + Deadline)
**File:** `lib/features/careers_portal/data/careers_portal_repository.dart`  
- `importJob()` previously set `skills: const []` and `deadline: ''`  
- Now calls `_extractSkills(description)` — scans cleaned description text against all `AppConstants.skillOptions` keywords (case-insensitive)  
- Sets `deadline` to **30 days from import date** (formatted `YYYY-MM-DD`)  
- Added `_extractSkills()` static helper method

### Firebase Data Integrity
**File:** `lib/services/firestore_service.dart`  
- Verified `postJob()` uses `FieldValue.serverTimestamp()` for `postedAt` ✓  
- Verified `Job.toFirestore()` serializes all fields: `skills`, `description`, `deadline`, `status` ✓  
- Verified imported jobs default to `status: 'active'` — immediately visible in job feed ✓  
- Fixed expired deadline `2026-05-30` in sample jobs → `2026-08-30`

---

## Files Modified

| File | Change summary |
|------|---------------|
| `lib/screens/main_screens.dart` | Quick Tour nav buttons, metric tile taps, label rename |
| `lib/services/firestore_service.dart` | `.limit(30/10)`, expired deadline fix |
| `lib/router.dart` | Remove Seekers tab, User Mode Banner |
| `lib/screens/feature_screens.dart` | Messages contact filter, Support section, `_SupportRow` widget |
| `lib/core/constants/app_constants.dart` | `supportEmail`, `supportPhone` constants |
| `lib/features/careers_portal/presentation/screens/careers_portal_screen.dart` | AppBar title/subtitle color fix |
| `lib/features/careers_portal/data/careers_portal_repository.dart` | Skill extraction, deadline, `filterLast30Days` default |
| `lib/services/careers_portal_service.dart` | `filterLast30Days` default, extra slug variants |

---

## Critical Restrictions Observed

- ✅ No architecture changes  
- ✅ No folder structure changes  
- ✅ No unnecessary refactoring  
- ✅ No UI redesign  
- ✅ No unrelated modules touched  
- ✅ No business logic changes outside requested scope  
- ✅ No shared logic removed  
- ✅ No unrelated Firebase collections modified
