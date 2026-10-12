# CarePaw — App Features (Table Format)

> Who can use what, at a glance. Only **2 account types** (thesis paper):
> **Owner** = pet owner, **O/A** = Owner/Admin (the clinic operator).
> "Own only" means owners see just their own things. Audit, Accounts, and
> Settings screens exist in code but are hidden from tabs (paper scope).

---

## 1. Accounts & Login

| Feature | What it does | Who |
|---|---|---|
| Create account | Join with email + password | Owner (first account ever becomes O/A) |
| Login / Logout | Sign in and out | Everyone |
| Forgot / reset password | New password through an email link | Everyone |
| Opening check | Logo screen sends you to Login or your home | Everyone |
| Own home screen | Owner home vs clinic home | Everyone |

## 2. Pets / Patients

| Feature | What it does | Who |
|---|---|---|
| Pet list | Owner sees own pets; O/A sees all | Everyone (Owner: own only) |
| Add a pet | Name, animal, breed, sex, birthday, photo | Owner |
| Pet details | Full info page incl. sex | Everyone (Owner: own only) |
| Edit pet | Change a pet's info | Owner (own only) |
| Search patients | Find a pet by name or owner | O/A |

## 3. Bookings

| Feature | What it does | Who |
|---|---|---|
| Book a visit | Pick pet, service, doctor, day, time, reason | Owner |
| Booking list | Owner sees own; O/A sees everyone's | Everyone (Owner: own only) |
| Booking details | Full info incl. service | Everyone (Owner: own only) |
| Approve / reject | Accept or decline a request | O/A |
| Change booking | Edit day, time, or reason (marks Rescheduled) | Owner (own only), O/A |
| Rescheduled status | Shows when a booking's date/time was changed | Everyone (Owner: own only) |
| Cancel booking | Cancel (always asks "are you sure?") | Owner (own only), O/A |
| Walk-in check-in | Add a visitor with no booking | O/A |
| Confirmation message | Owner is told the booking is confirmed | Owner (receives) |

## 4. Waiting Line

| Feature | What it does | Who |
|---|---|---|
| My place in line | Number, who's ahead, who's serving now | Owner |
| Self check-in | Check in from a confirmed booking | Owner |
| Live updates | Screen refreshes itself, no reload needed | Everyone |
| Run the line | Call next, to room, finish, skip, cancel | O/A |
| Cancelled status | Entry cancelled — visit will not happen | Everyone (Owner: own only) |
| Today's counts | Waiting, in room, now serving | O/A |

## 5. Visit Notes & Health History

| Feature | What it does | Who |
|---|---|---|
| Health history | Past visits per pet, newest first | Everyone (Owner: own only) |
| Visit details | One past visit, read-only | Everyone (Owner: own only) |
| New visit note | Findings, diagnosis, treatment, follow-up | O/A |
| Never edited | Old notes can't change; fixes are new notes | Rule for everyone |
| Vaccines list | Vaccines per pet with dates | Everyone (Owner: own only) |
| Add vaccine | Name, date given, next due date | O/A |
| Deworming records | Deworming product + date, filterable | Everyone (Owner: own only) / O/A adds |

## 6. Medicine Instructions (O/A only to write)

| Feature | What it does | Who |
|---|---|---|
| View instructions | Medicine, amount, how often, how long | Everyone (Owner: own only) |
| Write instructions | Create them (locked to clinic side) | O/A only |
| Mark ready / done | Update the status | O/A |
| Medicine-ready message | Owner is told the medicine is ready | Owner (receives) |

## 7. Medicine Stock

| Feature | What it does | Who |
|---|---|---|
| Stock list | All medicines with counts; low stock flagged | O/A |
| Stock details | Batches, expiry dates, full in/out history | O/A |
| Receive delivery | Add newly arrived stock | O/A |
| Give out medicine | Record medicine used for a patient | O/A |
| Fix a count | Correct a wrong count (asks for a reason) | O/A |
| Add new item | Register a brand-new medicine | O/A |

## 8. Scanning (Camera)

| Feature | What it does | Who |
|---|---|---|
| Scan list | Past scans | O/A |
| Camera scan | Read a medicine box or receipt | O/A |
| Person confirms | Nothing saves without a person approving | O/A |
| Save to stock | Confirmed scan updates stock + history | O/A |

## 9. Messages

| Feature | What it does | Who |
|---|---|---|
| Message list | Booking, line, medicine, reminder messages | Everyone (Owner: own only) |
| Message details | Full text of one message | Everyone (Owner: own only) |
| Mark read / delete | Tidy up messages | Everyone |
| Reminder settings | Choose which reminders stay on | Everyone |
| Send to owners | Clinic messages any owner | O/A |

## 10. Accounts & Activity History (hidden from tabs, kept in code)

| Feature | What it does | Who |
|---|---|---|
| Accounts list | Everyone, searchable | O/A (direct address only) |
| Add account | Create Owner/Admin or owner accounts | O/A (direct address only) |
| Change type / on-off | Switch type or disable an account | O/A (direct address only) |
| Activity history | Who did what and when (can't be edited) | O/A (direct address only) |
| Clinic settings | Name, hours, line rules, message texts | O/A (direct address only) |

## 11. My Profile (everyone)

| Feature | What it does | Who |
|---|---|---|
| View profile | Name, contact info, account badge | Everyone |
| Edit profile | Change name, phone, photo | Everyone |
| Bell shortcut | Jump to messages | Everyone |
| Log out | Sign out (asks first) | Everyone |

---

*Companions: `SYSTEM_WORKFLOW.md` (clinic-day story) and `APP_FLOWCHART.md`
(diagram + screen-by-screen story). `ALIGNED.md` tracks paper-vs-app fit.*
