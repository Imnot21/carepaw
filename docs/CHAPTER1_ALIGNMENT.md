# Chapter 1 vs. System Alignment

Source: `Chapter 1 draft.lara.docx`, checked against the codebase on branch `feature/neumorphism-design` (v1.0.4).
Updated: 2026-11-05. Every system change the paper needed is now built. What is left is listed under "Still open".

**Paper corrections applied** as tracked changes in `Chapter 1 draft.lara (corrected).docx`: #8, #9, #11, #14, #17, #19–#24.

Already aligned, no action: login with roles, date and time booking, home service with address, dogs and cats only, no emergency intake, real-time queue for owners, owners viewing health records, owner address, pet markings, scan review before saving, role lock on health records and inventory.

## Still open

| # | Owner | What | Why it is open |
|---|---|---|---|
| 16 | You | Deploy the new Firestore rules and the v1.0.4 web build: `flutter build web --release`, then `firebase deploy --only firestore:rules,hosting` | The rules are written and pass 30 emulator checks, but the live project still runs the old, open rules until this deploy runs. Claude Code's auto mode blocks production deploys, so you run it. Older phones must update to v1.0.4 after the deploy: their pet-owner lookups do not pass the new rules, and pet owners need the new notification rule to alert the clinic |
| 7 | Client | Confirm that "Medicine Dispensing" is what the paper calls "pet medicines" | The picker now lists exactly the paper's services. Only the label needs the client's yes |
| 9a | Group | Queue priority: keep Urgent / Routine, or require a priority on every entry | Your note: "can we force the client to have the queue priority since it handles the life of the pets taken to them" |
| 18 | Group | Web version | A web build is deployed, but the paper says mobile. Scanning uses `dart:io` and is not expected to work on the web. Android matches the paper |
| — | You | Release v1.0.4 on GitHub: `gh auth login`, tag `v1.0.4`, attach `build/app/outputs/flutter-apk/app-release.apk` | Needs your GitHub login |

## Done in v1.0.4

| Paper says | System now |
|---|---|
| FR-22 and FR-23: notify users of appointment and queue updates | The pet owner gets a notification when the clinic books, confirms, reschedules, cancels or marks a no-show, and when their pet is called from the queue. Every active Owner/Admin account gets one when a pet owner books, changes or cancels. New notifications pop up on the phone while the app is open or in the background (`NotificationAlerts`, Flutter Local Notifications) |
| Delimitations: accounts are deactivated, and the developer removes them permanently | The Accounts page has no Delete button. Switching an account off asks for confirmation; a deactivated account cannot sign in, and the rules stop users from switching themselves back on |
| No Cloud Functions or Cloud Messaging (free Spark plan) | The `deleteUser` Cloud Function, its HTTP call and the `functions/` folder are removed |

Emulator check: 30 of 30 pass (11 new cases for notifications and deactivation).

## Done in v1.0.3 (system changes for the paper)

| # | Paper says | System now |
|---|---|---|
| 7 | Services: consultation, vaccination, deworming, home service, pet medicines | The service picker lists Consultation, Home Service, Vaccination, Deworming and Medicine Dispensing. Older bookings keep their saved service |
| 8 | Owner/Veterinarian and Co-Manager share the Clinic Owner/Admin role | The role is shown as "Owner / Co-Manager". The clinic dashboard has **Accounts**, where the Owner creates the Co-Manager's account (the role choice starts on Owner / Co-Manager) |
| 12 | Clinic can view, monitor and update expiry dates | Each medicine on the Stock page shows its nearest expiry, marked Expired or Expires soon (30 days). The **Expiring soon** and **Expired** filters list what needs attention. The edit sheet lists every batch, and a wrong expiry date can be changed or removed. Each change is saved as a stock adjustment with the old and new date |
| 13 | Clinic can add and update medicine records | **Add stock** on the Stock page adds a medicine by hand: name, amount, unit, lot, supplier, expiry. A name already in stock is restocked as a new batch. The edit sheet also has **Add stock (restock)** |
| 14 | Pet Profile Management: pet owners create and update their pets; the clinic views and searches them (corrected paper) | The Patients tab has no Add Pet, so no pet is filed under the clinic's account. When the clinic opens a booking form (for example from a pet's page), the pet list holds every client's pets with the owner's name and a search box, nothing is picked automatically, and the booking is saved under the pet owner |
| 15 | Pets with the same name are hard to find | The Patients tab shows "Owner: name" on each pet, and search matches pet name, owner name, breed or markings |
| 16 | Objective 2.5: protect user and clinic information | `firestore.rules`: a pet owner reads only their own profile, the clinic's profiles and their own pets. Other clients' email, phone, address and pets are hidden. The Owner/Admin still reads everything. The repositories add the filters the rules need. Also fixed: creating an account no longer turns anyone on the first user's email domain (such as gmail.com) into an Owner/Admin |

Emulator check: `build/rules_test/rules.test.mjs`, run with `firebase emulators:exec --only firestore --project demo-carepaw "node build/rules_test/rules.test.mjs"`. 19 of 19 passed in v1.0.3; 30 of 30 pass in v1.0.4.

## Paper items (already applied as tracked changes)

| # | Issue | Paper fix |
|---|---|---|
| 11 | Database | Table 2 said MySQL; the system uses Cloud Firestore (Firebase) |
| 17 | "Update" health records | Records are append-only; the wording is "add and correct" |
| 19 | Wrong caption | "Figure B: Workflow of CAREPAW" shows the current manual process |
| 20 | Methodology | Waterfall, Figure 4. `docs/Q_AND_A.md` #14 is now rewritten for Waterfall. Check that the List of Figures no longer says "Agile SDLC Phases" |
| 21 | Technology note | Flutter and Dart, Firebase (Firestore, Auth, Cloud Messaging), Gemini. ML Kit is left out on purpose |
| 22 | Empty sections | Definition of Terms, IPO and Project Framework |
| 23 | Table of Contents and lists | Headings, table and figure numbers, page numbers |
| 24 | Small wording | Schedule vs. pending approval, Visit / Surgery record types, Sex, birth date only |

## B. Built, and added to the paper (#9)

Notifications and reminders, pet profile management, owners viewing health records, owner cancelling appointments, queue priority (Urgent / Routine), late and no-show handling, supplier receipt scanning, AI reading (Gemini; the ML Kit fallback stays out of the paper), and the low-stock count on the clinic dashboard.

Prescription scanning is still not reachable in the app, so it stays out of the paper. Expiry monitoring is now built (#12).
