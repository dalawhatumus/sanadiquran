# Connecting Sanadi to Firebase

These are one-time steps in a web browser. They cost nothing: Sanadi uses Firebase's free **Spark** plan, so no bank card is needed.

Until these steps are done, the app runs in **demo mode**. Everything works, but nothing is saved online.

After these steps, each new build from GitHub will:
- Sign in with Google.
- Save each person's profile online, so they get it back on a new phone.
- Send teacher applications to you for approval.
- Show the real number of available teachers.

You need:
- A Google account to own the project. Use the one you'll keep for Sanadi.
- Admin access to the GitHub repository.
- Two private files from Claude: `keystore.b64` and `keystore-password.txt`.

> **Keep `keystore.b64` and its password private and backed up** (e.g. in a password manager). They are Sanadi's signing key.
>
> - Every future update of the app must be signed with this key.
> - Never paste the key or its password anywhere except the GitHub **Secrets** page described below.
> - When the app goes on Google Play, Play App Signing can replace a lost key. Until then, losing it means testers reinstall the app.

---

## Part 1 · Create the Firebase project

1. Go to https://console.firebase.google.com and sign in.
2. Click **Create a project** (or **Add project**).
3. Name it `Sanadi` and accept the terms.
4. When asked about **Google Analytics**, turn it **off**. Then click **Create project**.
5. When it says the project is ready, click **Continue**.

## Part 2 · Add the Android app

1. On the project's home page, click the **Android** icon ("Add app").
2. Fill in the form:
   - **Android package name:** `sanadi.quran` (exactly this, it is permanent).
   - **App nickname:** `Sanadi Android`
   - **Debug signing certificate SHA-1:**
     ```
     C9:C1:E1:4E:24:16:65:E7:BD:56:79:5E:E1:CE:63:E9:C4:D0:B8:39
     ```
3. Click **Register app**.
4. Skip the remaining steps: click **Next** on "Download google-services.json", **Next** on the SDK step, then **Continue to console**. The build adds the settings itself, so no file is needed.
5. Add the second fingerprint:
   1. Click the gear icon (top left) → **Project settings**.
   2. Under **Your apps**, select **Sanadi Android** and click **Add fingerprint**.
   3. Paste the following and click **Save**:
      ```
      B3:15:1C:A2:6B:C1:15:40:F6:EE:21:10:28:DD:C5:15:02:35:E6:69:54:61:EF:FF:24:63:28:74:B1:7F:87:7E
      ```

## Part 3 · Turn on Google sign-in

1. Left menu: **Build → Authentication** (or **Security → Authentication**), then **Get started**.
2. Open the **Sign-in method** tab and click **Google**.
3. Set it up:
   - Switch **Enable** on.
   - **Project support email:** choose your email.
4. Click **Save**.
5. Click **Google** again and expand **Web SDK configuration**.
6. Copy the **Web client ID**, which ends in `.apps.googleusercontent.com`. This is `GOOGLE_WEB_CLIENT_ID` for Part 6.

## Part 4 · Create the database

1. Left menu: **Build → Firestore Database**, then **Create database**.
2. **Edition:** if asked, choose **Standard**.
3. **Location:** choose **`me-central2` (Dammam)**. This is permanent.
   - If it isn't offered, use `me-central1` (Doha).
   - If neither is offered, use `europe-west1` (Belgium).
4. **Rules:** choose **Start in production mode**, then **Create**.
5. When the database opens, go to the **Rules** tab.
6. Replace everything there with the contents of [`firebase/firestore.rules`](../firebase/firestore.rules) from this repository, then click **Publish**.

## Part 5 · Copy the project's settings

1. Gear icon → **Project settings**, **General** tab.
2. Copy these values. They are not secret: every Android app carries them.

| Name for GitHub | Where to find it |
|---|---|
| `FIREBASE_PROJECT_ID` | **Project ID** |
| `FIREBASE_SENDER_ID` | **Project number** |
| `FIREBASE_API_KEY` | **Web API Key**, which starts with `AIza` |
| `FIREBASE_APP_ID` | Under **Your apps → Sanadi Android**: **App ID**, which looks like `1:1234…:android:abcd…` |
| `FIREBASE_STORAGE_BUCKET` | Optional for now. Leave it out if you can't see it. |
| `GOOGLE_WEB_CLIENT_ID` | From Part 3 |

## Part 6 · Put the settings in GitHub

### Add the settings as Variables

1. Open the repository on GitHub → **Settings** → **Secrets and variables** → **Actions**.
2. Open the **Variables** tab.
3. For each name in the table above, click **New repository variable**, enter the name exactly as written, paste the value, and click **Add variable**.

### Add the signing key as Secrets

1. On the same page, open the **Secrets** tab.
2. Click **New repository secret** and add:
   - `SANADI_KEYSTORE_B64`: the entire contents of `keystore.b64`. It is one very long line; paste all of it.
   - `SANADI_KEYSTORE_PASSWORD`: the password in `keystore-password.txt`.

## Part 7 · Build, install and make yourself the admin

1. On GitHub, open **Actions** → **Android build** → **Run workflow** (on `main`). The build takes about 10 minutes.
2. Install the new APK from **Releases**.
   - **Uninstall the old Sanadi app first, once.** The new build is signed with the permanent key, and Android won't install it over a test build.
3. Open the app, choose your language and tap **Continue with Google**.
4. Find your user ID:
   1. In Firebase: **Authentication → Users**.
   2. Find your email and copy the **User UID**, a long code.
5. Make yourself an admin:
   1. In Firebase: **Firestore Database → Data → Start collection**.
   2. **Collection ID:** `admins` → **Next**.
   3. **Document ID:** paste your User UID.
   4. Add one field: name `role`, type string, value `admin`.
   5. Click **Save**.
6. Check that it worked:
   - Close and reopen the app. **Settings** now shows **Teacher applications**, where you approve or turn down volunteers.
   - Settings also shows "Connected: your profile is saved online" near the bottom. If it says "Demo mode", a variable from Part 6 is missing.

To add another admin later, repeat step 5 with their User UID.

---

### If something goes wrong

- **"Couldn't sign in"**, or the Google window closes straight away. Usually one of these:
  - A fingerprint from Part 2 is missing.
  - `GOOGLE_WEB_CLIENT_ID` is wrong.
  - The APK was built before the secrets were added. Run the workflow again.
- **Settings shows "Demo mode".** One of `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID` or `GOOGLE_WEB_CLIENT_ID` is missing from the GitHub Variables. Check the spelling, then build again.
- **Approve / Not approved fails.** Check two things:
  - The rules from Part 4 were published.
  - Your `admins` document ID is exactly your User UID.

---

## When the rules change

Some updates change [`firebase/firestore.rules`](../firebase/firestore.rules). The release notes say so. When they do:

1. In Firebase, open **Firestore Database → Rules**.
2. Replace everything with the new file's contents.
3. Click **Publish**.

The rules are tested against the Firestore emulator before every change:

```
cd firebase/test && npm install && npm test
```
