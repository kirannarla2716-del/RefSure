# RefSure — Where real referrals happen

> A Flutter + Firebase mobile app connecting job seekers with company insiders for real, verified referrals.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-orange?logo=firebase)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-green)

---

## What is RefSure?

RefSure bridges the gap between job seekers and company insiders.  
Seekers find verified employees willing to refer them. Providers review applicants and refer the best fits — building their reputation with every successful placement.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3 + Dart |
| Backend | Firebase (Auth · Firestore · Storage) |
| State Management | Provider + ChangeNotifier |
| Navigation | GoRouter |
| Authentication | Email/Password + Google Sign-In |
| Database | Cloud Firestore (real-time streams) |
| File Storage | Firebase Storage |

---

## Features

### For Job Seekers
- 🔍 Browse jobs with **AI-powered skill match scoring**
- 📊 Track application status in real time
- 💬 Direct message referral providers
- 🔔 Instant notifications on status changes
- 👤 Profile with photo upload

### For Referral Providers
- 🏆 Badge system — Bronze → Platinum based on referrals made
- 📋 Review applicants ranked by skill match
- ✅ One-tap Refer / Shortlist / Skip
- 📢 Post job openings directly
- 🔎 Search candidate talent pool

### Platform
- iOS · Android · Web (Chrome)
- Real-time Firestore listeners
- Firebase Auth with Google Sign-In
- Profile photo upload to Firebase Storage

---

## Project Structure

```
lib/
├── main.dart                    Firebase init + splash screen
├── router.dart                  GoRouter + bottom nav shell
├── models/models.dart           AppUser, Job, Application, Message, Notification
├── services/
│   ├── auth_service.dart        Firebase Auth (email + Google)
│   ├── firestore_service.dart   All Firestore CRUD + real-time streams
│   └── storage_service.dart     Firebase Storage (profile photos)
├── providers/app_provider.dart  Central state + stream management
├── screens/
│   ├── auth_screen.dart         Sign In / Sign Up
│   ├── onboarding_screen.dart   3-step profile setup
│   ├── main_screens.dart        Home, Jobs, Job Detail, Providers, Notifications
│   └── feature_screens.dart     Applications, Dashboard, Messages, Profile, Post Job
└── widgets/
    ├── common.dart              Avatar, SkillChip, StatusPill, MatchScore
    └── cards.dart               JobCard, ProviderCard
```

---

## Getting Started

### Prerequisites
- Flutter 3.19+
- Firebase project ([console.firebase.google.com](https://console.firebase.google.com))

### Setup

```bash
# 1. Clone
git clone https://github.com/kirannarla2716-del/RefSure.git
cd RefSure

# 2. Install FlutterFire CLI
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"

# 3. Connect your Firebase project
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID

# 4. Install dependencies
flutter pub get

# 5. Run
flutter run -d chrome        # Web (instant, no setup)
flutter run                  # iOS Simulator / Android device
```

### Firebase Setup
See **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** for:
- Enabling Auth, Firestore, Storage
- Firestore security rules
- Android `google-services.json` setup
- iOS `GoogleService-Info.plist` setup

---

## Screenshots

> Coming soon

---

## Firestore Collections

```
/users/{uid}          — profiles (seekers + providers)
/jobs/{jobId}         — job postings
/applications/{id}    — seeker → job applications
/messages/{id}        — direct messages
/notifications/{id}   — per-user notifications
```

---

## License

MIT © 2026 [kirannarla2716-del](https://github.com/kirannarla2716-del)
