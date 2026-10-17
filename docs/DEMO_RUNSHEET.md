# CarePaw — Demo Run-Sheet

The operator + owner demo script. Every screen and action below was
screen-verified on the demo build (emulator, 1080×2424).

## Before you start (30 seconds)

1. Emulator at phone size — if it was resized for a tablet test, restore with
   `adb shell wm size reset` and `adb shell wm density reset`.
2. Font scale at default: `adb shell settings put system font_scale 1.0`.
3. Launch the app fresh. If the **Device Preview** frame is showing (mockup
   bezel or a settings rail on the right), tap its toggle once — the app runs
   full-screen. Release builds never show it.
4. Accounts: `vet@carepaw.com` / `Carepaw123` (operator), or `admin@carepaw.com`
   / `Carepaw123`. Owner accounts register from the sign-up screen.

---

## Operator flow (≈5–7 minutes)

| # | Screen | What to show / say |
|---|--------|--------------------|
| 1 | **Login** | Email + password auth; the app routes by role automatically. Sign in as `vet@carepaw.com`. |
| 2 | **Clinic dashboard** | The pulse strip — waiting / today's bookings / low stock. "Clinic work" grid is the operator's launchpad for every module. |
| 3 | **Booking tab** | Appointment list with Upcoming / Past. Open a booking → detail shows its status; confirm / decline actions. |
| 4 | **Patients tab** | Pet cards; open one → pet profile with owner, species, age, and a Records entry point. |
| 5 | **Records** | Per-pet, append-only health history + vaccinations. "Records are never deleted — only corrected." |
| 6 | **Line tab** | Queue management: Waiting / In Room / Now Serving stats; check-in moves a pet into the queue. |
| 7 | **Stock tab** | Inventory list with category filters; item detail shows batches and expiry tracking. Low stock ties back to the dashboard pulse. |
| 8 | **Bell → Notifications** | Tap the bell (top-right of the dashboard). Create a test notification with the FAB — it persists and appears with an unread dot. Mark Read, open its detail page. |
| 9 | **Profile tab** | Settings: notification settings, help, logout. |

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
  The preview frame defaults on at cold start; toggle it off (step 3 above).
- **Dialog + keyboard** — the app lifts dialogs above the keyboard (show it —
  it's a verified behavior, not a workaround).
- **Low stock shows 0** — that's live data. Add an item in Stock with quantity
  below its reorder threshold to light the pulse up.

## Do not open (reserved surfaces)

Staff/Vet/Admin dashboards, Scan, Audit log, and user management are
implemented but parked by design after the defense — keep the demo on the
operator + owner flows above.
