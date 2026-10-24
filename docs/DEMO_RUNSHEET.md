# CarePaw — Demo Run-Sheet

The operator + owner demo script. Every screen and action below was
screen-verified on the demo build (emulator, 1080×2424).

## Before you start (30 seconds)

1. Emulator at phone size — if it was resized for a tablet test, restore with
   `adb shell wm size reset` and `adb shell wm density reset`.
2. Font scale at default: `adb shell settings put system font_scale 1.0`.
3. Launch the app fresh. Device Preview is off unless the build passes
   `--dart-define=DEVICE_PREVIEW=true`; release builds never show it.
4. Accounts (passwords are kept privately by the team, not in this repo):
   - `vet@carepaw.com` — Owner/Admin (clinic operator).
   - `admin@carepaw.com` — **Pet Owner** despite the name. It has no clinic
     access; inventory reads are denied by Firestore rules by design.
   - New owner accounts can register from the sign-up screen.

---

## Operator flow (≈5–7 minutes)

| # | Screen | What to show / say |
|---|--------|--------------------|
| 1 | **Login** | Email + password auth; the app routes by role automatically. Sign in as `vet@carepaw.com`. |
| 2 | **Clinic dashboard** | The pulse strip — waiting / today's bookings / low stock. "Clinic work" grid is the operator's launchpad for every module. |
| 3 | **Booking tab** | Appointment list with Upcoming / Past. Open a *Pending Approval* booking → tap **Approve Booking** (clinic only). Then Check In → Start → Complete. Status words: Pending Approval, Approved, Checked In, In Progress, Completed. |
| 4 | **Patients tab** | Pet cards; open one → pet profile with owner, species, age, and a Records entry point. |
| 5 | **Records** | Per-pet, append-only health history + vaccinations. Open a record → tap the pencil → **Correct Record**: the form opens prefilled and asks for a reason. **Save Correction** adds a new entry marked *Correction*; the original stays, marked *Corrected*, and its page shows when and why. "Records are never deleted — only corrected." |
| 6 | **Line tab** | Queue management: Waiting / Being Served / Now Serving stats; check-in moves a pet into the queue. |
| 7 | **Stock tab** | Inventory list with category filters; item detail shows batches and expiry tracking. Low stock ties back to the dashboard pulse. |
| 8 | **Scan tab** | Tap **New Scan** → pick *Medicine Box* → **Take Photo** of a real box (or Gallery). Text is read on the phone (Google ML Kit, no internet needed) and the app suggests Name / Expiry / Lot. **Save for Review** stores it as *Pending*; open it → **Confirm** or **Reject**. After Confirm, **Add to Stock** → pick the medicine → the batch form opens with lot and expiry filled in; enter the quantity and save (it appears in Stock with a stock-in history entry). "OCR output is never trusted blindly — a person confirms every scan." |
| 9 | **Bell → Notifications** | Tap the bell (top-right of the dashboard). Create a test notification with the FAB — it persists and appears with an unread dot. Open its detail page; **View Appointment / View Queue** jumps to the related screen. |
| 10 | **Profile tab** | Settings: notification settings, Help & Support (clinic contact + app version), logout. |

## Owner flow (≈3 minutes)

| # | Screen | What to show / say |
|---|--------|--------------------|
| 1 | **Logout → owner login** | Use an owner account (or register one live in 30 seconds). |
| 2 | **Owner home** | A different app for a different role: pets first, no clinic controls. |
| 3 | **My Pets** | Owner's pets → detail. |
| 4 | **Appointments** | Owner view of bookings with status. |
| 5 | **Queue** | Owner view of the live queue position. |

---

## If something goes wrong (fallbacks)

- **Notifications list looks empty** — the create-test flow is the demo: tap
  the FAB on the notifications screen and create one live. It persists and
  shows "Just now".
- **App looks off after a resize/rotation test** — force-stop and relaunch.
- **Dialog + keyboard** — the app lifts dialogs above the keyboard (show it —
  it's a verified behavior, not a workaround).
- **Scan finds no text** — retake closer, flat, in good light; a printed
  box label works best. Gallery works too if the camera is awkward on stage.
- **Low stock shows 0** — that's live data. Add an item in Stock with quantity
  below its reorder threshold to light the pulse up.

## Do not open (reserved surfaces)

Staff/Vet/Admin dashboards, Audit log, and user management are
implemented but parked by design after the defense — keep the demo on the
operator + owner flows above.
