# Related Technologies — CarePaw

A surface-level list of the technologies used in this project and what each one
does.

---

## Frontend

| Technology | What it does |
|---|---|
| **Flutter** | Builds the app for Android, iOS, and Web from one codebase. |
| **Dart** | The programming language Flutter is written in. |
| **Material Design** | Google's standard component and style system, used as the visual base. |

## App Logic

| Technology | What it does |
|---|---|
| **BLoC** | Manages app state so screens react to changes automatically. |
| **GetIt** | Provides the shared services each screen depends on. |
| **go_router** | Handles navigation between screens and blocks unauthorised routes. |

## Backend

| Technology | What it does |
|---|---|
| **Google Firebase** | The cloud platform the app runs on. |
| **Cloud Firestore** | Stores all app data as documents in named collections. |
| **Firebase Authentication** | Handles accounts, logins, and passwords. |
| **Cloud Functions** | Runs server-side code for actions the app is not allowed to do directly. |
| **Firebase Hosting** | Publishes the app to the web. |

## Security

| Technology | What it does |
|---|---|
| **Firestore Security Rules** | Decides who can read and write each piece of data, enforced on the server. |
| **Role-Based Access** | Gives pet owners, staff, veterinarians, and admins different permissions. |
| **SharedPreferences** | Stores small settings and session data on the device. |

## Camera and AI Text Recognition

The scanning feature photographs medicine boxes and receipts, reads the text
automatically, and pre-fills inventory data so staff do not type it in by hand.

| Technology | What it does |
|---|---|
| **Device Camera** | Captures the photo of the medicine box or receipt directly inside the app. |
| **Google Gemini API** | Reads the text from the photo and returns the medicine name, dosage, quantity, and batch details as structured data. |
| **Firebase Cloud Functions** | Calls the AI securely from the server so the API key is never exposed in the app. |
| **Human Verification Step** | Shows the AI's extracted values and requires staff to confirm or correct them before anything is saved. |

Because the AI's reading is never saved automatically, a misread label cannot
corrupt the inventory records. The AI proposes; a person decides.

## Design

| Technology | What it does |
|---|---|
| **Custom Design System** | A central set of colours, spacing, and components so the app looks consistent. |
| **Google Fonts** | Supplies the Nunito typeface used for headings and numbers. |

## Testing and Tools

| Technology | What it does |
|---|---|
| **Flutter Test, bloc_test, Mocktail** | Automated tests that check features work correctly. |
| **Flutter Lints** | Catches errors and bad practices while writing code. |
| **Android Studio, Xcode, Gradle** | The toolchains that compile and package the Android and iOS builds. |

---

*CarePaw uses no local server and no separate backend language — Firebase
provides the whole cloud layer.*
