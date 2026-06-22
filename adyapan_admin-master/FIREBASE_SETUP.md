# Firebase Push Notification Setup

Push notifications are sent to principals whenever an admin sends a message.
Follow these steps to activate them.

---

## 1. Create a Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `adyapan-admin` (or any name).
3. Enable **Google Analytics** (optional).

---

## 2. Add the Android App

1. In the Firebase Console, click **Add app → Android**.
2. Enter package name: `com.adyapan.adyapan_admin`
3. Download **`google-services.json`** and place it at:
   ```
   android/app/google-services.json
   ```
4. The `build.gradle.kts` already has the Google Services plugin applied.

---

## 3. Add the iOS App (optional)

1. Click **Add app → Apple (iOS)**.
2. Enter bundle ID from `ios/Runner/Info.plist`.
3. Download **`GoogleService-Info.plist`** and place it at:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

---

## 4. Configure the Backend (Render / Server)

1. In Firebase Console → **Project Settings → Service Accounts**.
2. Click **Generate new private key** → download the JSON file.
3. Set the environment variable on Render (or your `.env`):

```
FIREBASE_SERVICE_ACCOUNT_JSON=<paste the entire JSON content as a single line>
```

> **Tip:** Minify the JSON before pasting:  
> `cat firebase-service-account.json | python3 -m json.tool --compact`

---

## 5. Run database migration

The `principals` table now has an `fcm_token` column.  
Run the Prisma migration to apply it:

```bash
cd backend
npx prisma db push
```

---

## 6. Run `flutter pub get`

```bash
flutter pub get
```

---

## How it works

| Event | What happens |
|---|---|
| Principal logs in | App requests notification permission, gets FCM token, sends it to `PATCH /api/v1/admin-messages/fcm-token` |
| Token refreshed | `onTokenRefresh` listener automatically re-sends the new token |
| Admin sends message | Backend writes to `notifications` table **and** calls FCM to push immediately |
| App in foreground | `flutter_local_notifications` shows a heads-up notification |
| App in background / killed | FCM delivers the notification natively via the OS |
| Firebase not configured | App falls back gracefully to 30-second polling — no crash |
