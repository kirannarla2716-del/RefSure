# RefSure — Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project" → Name it "refsure"
3. Disable Google Analytics (optional)
4. Click "Create project"

---

## Step 2: Enable Firebase Services

In your Firebase Console:

### Authentication
- Build → Authentication → Get started
- Enable: **Email/Password** and **Google**

### Firestore Database
- Build → Firestore Database → Create database
- Start in **test mode** (for development)
- Choose region: **asia-south1** (Mumbai — closest to India)

### Storage
- Build → Storage → Get started
- Start in test mode

---

## Step 3: Add Flutter App to Firebase

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

In your project folder:
```bash
flutterfire configure --project=your-project-id
```

This auto-generates `lib/firebase_options.dart` with your config.

---

## Step 4: Android Setup

1. In Firebase Console → Project Settings → Add app → Android
2. Package name: `com.refsure.app`
3. Download `google-services.json`
4. Place it at `android/app/google-services.json`

In `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
}
```

In `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## Step 5: iOS Setup

1. In Firebase Console → Project Settings → Add app → iOS
2. Bundle ID: `com.refsure.app`
3. Download `GoogleService-Info.plist`
4. Place it at `ios/Runner/GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Drag `GoogleService-Info.plist` into the project

---

## Step 6: Firestore Security Rules

In Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Jobs: authenticated users can read; only providers can create
    match /jobs/{jobId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'provider';
      allow update, delete: if request.auth.uid == resource.data.providerId;
    }
    
    // Applications: seekers create, providers update
    match /applications/{appId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.seekerId ||
         request.auth.uid == resource.data.providerId);
      allow create: if request.auth != null &&
        request.auth.uid == request.resource.data.seekerId;
      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.seekerId ||
         request.auth.uid == resource.data.providerId);
    }
    
    // Messages: only conversation participants
    match /messages/{msgId} {
      allow read, write: if request.auth != null &&
        (request.auth.uid == resource.data.fromId ||
         request.auth.uid == resource.data.toId);
    }
    
    // Notifications: only the recipient
    match /notifications/{notifId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## Step 7: Run the app

```bash
flutter pub get
flutter run
```

---

## Firestore Collections Structure

```
/users/{uid}
  - id, role, name, headline, company, verified
  - skills[], bio, location, experience
  - referralsMade, successRate, profileComplete
  - createdAt, lastActiveAt

/jobs/{jobId}
  - providerId, company, title, department
  - location, workMode, minExp, maxExp
  - salaryMin, salaryMax, skills[], description
  - status, applicants, deadline, postedAt

/applications/{appId}
  - jobId, seekerId, providerId
  - status, matchScore, providerNote
  - appliedAt, updatedAt

/messages/{msgId}
  - fromId, toId, text, sentAt, read

/notifications/{notifId}
  - userId, type, text, read, createdAt
```
