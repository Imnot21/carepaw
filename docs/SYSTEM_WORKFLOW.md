# CarePaw — How the System Works (Plain-Words Guide)

> Who is this for: clinic owners, staff, and school panel readers who don't need
> computer terms. Everything here describes what really happens in the app.

---

## Meet the people in the story

There are 2 kinds of users (thesis paper). Think of them as 2 characters:

1. **Pet Owner (the customer)** — owns the pet, books visits, waits in line.
2. **Owner/Admin (the clinic)** — the owner-veterinarian running DocMyk's
   PILA VET HUB. One account does everything: bookings, the waiting line,
   patient files, visit notes, vaccines, deworming, medicine instructions,
   stock, scanning, and messages.

---

## The whole story, start to finish

> Lina and her dog Bingo will walk us through the full story.

**1. Lina joins.**
Lina makes an account with her email and password, then logs in.

**2. Lina adds Bingo.**
She adds her dog: name (Bingo), what animal (dog), breed, sex, birthday,
and a photo if she wants. She can add more pets later.

**3. Lina books a visit.**
She picks Bingo, picks a service (for example Consultation or Vaccination),
picks a day and time, and writes the reason — for example "yearly checkup"
or "Bingo keeps scratching his ear."
The booking is sent to the clinic as "waiting for approval."

**4. The clinic answers.**
The Owner/Admin sees Lina's booking on the list and approves it (or moves
it to a different time — the booking then shows "Rescheduled"). Lina gets
a message that her visit is confirmed.

**5. Visit day — Lina checks in.**
Lina arrives at the clinic. The Owner/Admin checks her in, and Bingo joins
the waiting line for that day.

**6. Lina watches the line on her phone.**
On her phone Lina sees where Bingo is: "3rd in line," "2nd in line,"
"You're next." She doesn't need to keep asking the counter.

**7. The clinic calls the next pet.**
When it's Bingo's turn, the Owner/Admin calls them and brings them to the
examination room. The line on everyone's phone moves up. (If a visit is
called off, the entry is marked Cancelled.)

**8. Bingo is examined.**
The Owner/Admin opens Bingo's file and sees all his past visits. After the
checkup, the visit notes are written down: what was found, what was done,
what to watch for at home.

**9. Vaccines, deworming, and medicine instructions, if needed.**
If Bingo needs a vaccine or deworming, it is recorded in his history. If
Bingo needs medicine, the medicine instructions are written — what
medicine, how much, and how often.

**10. The medicine is prepared.**
The Owner/Admin reads the instructions, prepares the medicine, and updates
the stock count (for example "20 bottles left"). If a medicine box is
scanned with the phone camera, a person always double-checks the
result before saving — the machine is never trusted on its own.

**11. Lina goes home, everything is saved.**
Lina gets a message: visit done, medicine ready, or a reminder for the next
visit. Anytime later, she can open Bingo's health history and see every
visit, vaccine, and deworming treatment.

**12. What stays behind the scenes.**
The accounts screen and the activity history (who did what and when) exist
in the system but are hidden from the daily screens — the paper only asks
for the 4 main jobs (bookings, records, line, stock).

**One rule that never changes:** old visit notes are never edited or
deleted. If a mistake is found, a new correction note is added on top, so
the full history is always there.

---

## The pet owner's journey, step by step

```
Join → Add pet → Book a visit → Get confirmation →
Arrive & check in → Watch the line → See the doctor →
Get message → View pet's health history anytime
```

What the pet owner can do:

- Make an account and manage their own profile
- Add, view, and edit their own pets (incl. sex)
- Book (with service), view, change, or cancel their own visits
- Check in and see their place in line
- Read their own pets' visit history, vaccines, and deworming (view only)
- Get messages: booking confirmation, "you're next," medicine ready, reminders

What the pet owner cannot do:

- See other people's pets or visits
- Write visit notes or medicine instructions
- Change medicine stock
- See the activity history or manage accounts

---

## The Owner/Admin's journey, step by step

```
Log in → See today's list → Approve bookings → Check people in →
Run the waiting line → Open patient files → Write visit notes →
Add vaccines & deworming → Write medicine instructions →
Handle medicine stock & scanning → Send messages to owners
```

What the Owner/Admin can do:

- See all bookings and approve, move (Rescheduled), or cancel them
- Check people in and run the waiting line (call next, move to room,
  finish, skip, cancel)
- Add walk-in visitors who didn't book
- See all pets and full visit histories
- Write visit notes, vaccines, deworming, and medicine instructions
- Add, count, and give out medicine stock
- Scan medicine boxes and receipts (always with a person confirming)
- Send messages to any owner

What the Owner/Admin cannot do:

- Edit or delete old visit notes (corrections are new notes on top)
- See other clinics (the system serves DocMyk's PILA VET HUB only)

---

## Who can do what — one simple table

| What needs doing | Owner | Owner/Admin |
|---|---|---|
| Manage own pets (incl. sex) | Yes | — |
| Book own visit (with service) | Yes | — |
| Approve and manage all bookings | — | Yes |
| Run the waiting line | view only | Yes |
| Write visit notes | — | Yes |
| Add vaccines & deworming | — | Yes |
| Write medicine instructions | — | Yes |
| Handle medicine stock | — | Yes |
| Scan medicine boxes | — | Yes |
| Add accounts / see activity history | — | Hidden (in code, not on tabs) |
| Book own visit | Yes | — | — | — |
| Approve and manage all bookings | — | Yes | Yes | Yes |
| Run the waiting line | view only | Yes | Yes | Yes |
| Write visit notes | — | Yes (help) | Yes | Yes |
| Write medicine instructions | — | — | Yes | Needs doctor |
---

## Our situation: only one clinic — DONE

This guide used to describe a bigger clinic with 4 account types. That has
now been changed to match the thesis paper exactly:

- **2 account types only:** Pet Owner + Owner/Admin (DocMyk's PILA VET HUB).
- The Owner/Admin's daily login runs everything: bookings, line, patients,
  records, vaccines, deworming, medicine instructions, stock, scanning.
- Accounts, activity history, and settings still exist in the system but
  are hidden from the daily screens — just as the paper's scope asks for
  the 4 main jobs only.
- The old 4-role version is kept as a backup copy of the project, in case
  the clinic grows one day.

In the school paper, write: *"The system provides 2 user sides — pet
owners and the Owner/Admin — per Chapter 1. The Owner/Admin account covers
counter, clinical, and management duties for the single-clinic
deployment."*

---

*End of guide. If anything in the clinic's daily routine changes, this file
should be updated to match — it is the plain-words mirror of how the app
really behaves.*
