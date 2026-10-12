# CarePaw — App Features (Table Format)

> Who can use what, at a glance. Short names: **Owner** = pet owner,
> **Desk** = front desk worker, **Doctor** = animal doctor,
> **Manager** = boss. "Own only" means owners see just their own things.

---

## 1. Accounts & Login

| Feature | What it does | Who |
|---|---|---|
| Create account | Join with email + password | Owner (Manager also adds accounts, see §10) |
| Login / Logout | Sign in and out | Everyone |
| Forgot / reset password | New password through an email link | Everyone |
| Opening check | Logo screen sends you to Login or your home | Everyone |
| Own home screen | Each account type opens its own home | Everyone |

## 2. Pets / Patients

| Feature | What it does | Who |
|---|---|---|
| Pet list | Owner sees own pets; clinic sees all | Everyone (Owner: own only) |
| Add a pet | Name, animal, breed, birthday, photo | Owner |
| Pet details | Full info page for one pet | Everyone (Owner: own only) |
| Edit pet | Change a pet's info | Owner (own only) |
| Search patients | Find a pet by name or owner | Desk, Doctor, Manager |

## 3. Bookings

| Feature | What it does | Who |
|---|---|---|
| Book a visit | Pick pet, doctor, day, time, reason | Owner |
| Booking list | Owner sees own; clinic sees everyone's | Everyone (Owner: own only) |
| Booking details | Full info for one booking | Everyone (Owner: own only) |
| Approve / reject | Accept or decline a request | Desk, Doctor, Manager |
| Change booking | Edit day, time, or reason | Owner (own only), Desk, Doctor, Manager |
| Cancel booking | Cancel (always asks "are you sure?") | Owner (own only), Desk, Doctor, Manager |
| Walk-in check-in | Add a visitor with no booking | Desk, Manager |
| Confirmation message | Owner is told the booking is confirmed | Owner (receives) |

## 4. Waiting Line

| Feature | What it does | Who |
|---|---|---|
| My place in line | Number, who's ahead, who's serving now | Owner |
| Self check-in | Check in from a confirmed booking | Owner |
| Live updates | Screen refreshes itself, no reload needed | Everyone |
| Run the line | Call next, to room, finish, skip | Desk, Doctor, Manager |
| Today's counts | Waiting, in room, now serving | Desk, Manager |

## 5. Visit Notes & Health History

| Feature | What it does | Who |
|---|---|---|
| Health history | Past visits per pet, newest first | Everyone (Owner: own only) |
| Visit details | One past visit, read-only | Everyone (Owner: own only) |
| New visit note | Findings, diagnosis, treatment, follow-up | Doctor (Desk helps, Manager) |
| Never edited | Old notes can't change; fixes are new notes | Rule for everyone |
| Vaccines list | Vaccines per pet with dates | Everyone (Owner: own only) |
| Add vaccine | Name, date given, next due date | Desk, Doctor, Manager |

## 6. Medicine Instructions (doctor only)

| Feature | What it does | Who |
|---|---|---|
| View instructions | Medicine, amount, how often, how long | Everyone (Owner: own only) |
| Write instructions | Create them (locked for safety) | Doctor only |
| Mark ready / done | Update the status | Doctor |
| Medicine-ready message | Owner is told the medicine is ready | Owner (receives) |

## 7. Medicine Stock

| Feature | What it does | Who |
|---|---|---|
| Stock list | All medicines with counts; low stock flagged | Desk, Manager (Doctor views) |
| Stock details | Batches, expiry dates, full in/out history | Desk, Manager (Doctor views) |
| Receive delivery | Add newly arrived stock | Desk, Manager |
| Give out medicine | Record medicine used for a patient | Desk, Manager |
| Fix a count | Correct a wrong count (asks for a reason) | Desk, Manager |
| Add new item | Register a brand-new medicine | Desk, Manager |

## 8. Scanning (Camera)

| Feature | What it does | Who |
|---|---|---|
| Scan list | Past scans | Desk, Doctor, Manager |
| Camera scan | Read a medicine box or receipt | Desk, Doctor, Manager |
| Person confirms | Nothing saves without a person approving | Desk, Doctor, Manager |
| Save to stock | Confirmed scan updates stock + history | Desk, Manager |

## 9. Messages

| Feature | What it does | Who |
|---|---|---|
| Message list | Booking, line, medicine, reminder messages | Everyone (Owner: own only) |
| Message details | Full text of one message | Everyone (Owner: own only) |
| Mark read / delete | Tidy up messages | Everyone |
| Reminder settings | Choose which reminders stay on | Everyone |
| Send to owners | Clinic messages any owner | Desk, Doctor, Manager |

## 10. Accounts & Activity History (manager only)

| Feature | What it does | Who |
|---|---|---|
| Accounts list | Everyone: owners, workers, doctors | Manager |
| Add account | Create worker, doctor, or owner accounts | Manager |
| Change type | Switch someone's type | Manager |
| Turn on / off | Disable an account when someone leaves | Manager |
| Search + filter | Find people by name or type | Manager |
| Activity history | Who did what and when (can't be edited) | Manager |
| Clinic settings | Name, hours, line rules, message texts | Manager |

## 11. My Profile (everyone)

| Feature | What it does | Who |
|---|---|---|
| View profile | Name, contact info, account badge | Everyone |
| Edit profile | Change name, phone, photo | Everyone |
| Bell shortcut | Jump to messages | Everyone |
| Log out | Sign out (asks first) | Everyone |

---

*Companions: `SYSTEM_WORKFLOW.md` (clinic-day story) and `APP_FLOWCHART.md`
(diagram + screen-by-screen story).*
