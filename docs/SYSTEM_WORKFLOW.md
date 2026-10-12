# CarePaw — How the System Works (Plain-Words Guide)

> Who is this for: clinic owners, staff, and school panel readers who don't need
> computer terms. Everything here describes what really happens in the app.

---

## Meet the people in the story

There are 4 kinds of users. Think of them as 4 characters:

1. **Pet Owner (the customer)** — owns the pet, books visits, waits in line.
2. **Front Desk Worker** — the person at the counter. Handles bookings, the
   waiting line, check-ins, medicine stock, and scanning.
3. **Animal Doctor** — the one who examines the pet, writes the visit notes,
   gives vaccines, and tells what medicine to take.
4. **Manager** — the boss of the system. Adds worker accounts and checks the
   activity history (who did what and when).

---

## The whole story, start to finish

> Lina and her dog Bingo will walk us through the full story.

**1. Lina joins.**
Lina makes an account with her email and password, then logs in.

**2. Lina adds Bingo.**
She adds her dog: name (Bingo), what animal (dog), breed, birthday, and a photo
if she wants. She can add more pets later.

**3. Lina books a visit.**
She picks Bingo, picks a day and time, picks a doctor, and writes the reason
— for example "yearly checkup" or "Bingo keeps scratching his ear."
The booking is sent to the clinic as "waiting for approval."

**4. The front desk worker answers.**
The worker sees Lina's booking on their list. They approve it (or suggest a
different time if the slot is full). Lina gets a message that her visit is
confirmed.

**5. Visit day — Lina checks in.**
Lina arrives at the clinic. The worker checks her in, and Bingo joins the
waiting line for that day.

**6. Lina watches the line on her phone.**
On her phone Lina sees where Bingo is: "3rd in line," "2nd in line,"
"You're next." She doesn't need to keep asking the counter.

**7. The worker calls the next pet.**
When it's Bingo's turn, the worker calls them and brings them to the
examination room. The line on everyone's phone moves up.

**8. The doctor examines Bingo.**
The doctor opens Bingo's file and sees all his past visits. After the
checkup, the doctor writes down what happened: what they found, what they
did, what to watch for at home.

**9. Vaccines and medicine instructions, if needed.**
If Bingo needs a vaccine, the doctor records it. If Bingo needs medicine,
only the doctor can write the medicine instructions — what medicine, how
much, and how often. Nobody else is allowed to do this part.

**10. The worker prepares the medicine.**
The worker reads the doctor's instructions, prepares the medicine, and
updates the stock count (for example "20 bottles left"). If they scan a
medicine box with the phone camera, a person always double-checks the
result before saving — the machine is never trusted on its own.

**11. Lina goes home, everything is saved.**
Lina gets a message: visit done, medicine ready, or a reminder for the next
visit. Anytime later, she can open Bingo's health history and see every
visit and vaccine.

**12. The manager watches over everything.**
The manager can add new worker or doctor accounts, change what someone is
allowed to do, and turn an account off if someone leaves. The manager can
also open the activity history — a list showing who did what and when —
so nothing happens secretly.

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
- Add, view, and edit their own pets
- Book, view, change, or cancel their own visits
- Check in and see their place in line
- Read their own pets' visit history and vaccines (view only)
- Get messages: booking confirmation, "you're next," medicine ready, reminders

What the pet owner cannot do:

- See other people's pets or visits
- Write visit notes or medicine instructions
- Change medicine stock
- See the activity history or manage accounts

---

## The front desk worker's journey, step by step

```
Log in → See today's list → Approve bookings → Check people in →
Run the waiting line → Help the doctor with files → Handle medicine
stock & scanning → Send messages to owners
```

What the front desk worker can do:

- See all bookings and approve, move, or cancel them
- Check people in and run the waiting line (call next, move to room, finish)
- Add walk-in visitors who didn't book
- See all pets and visit histories (to help owners and doctors)
- Help write visit notes (but not medicine instructions)
- Add, count, and give out medicine stock
- Scan medicine boxes and receipts (always with a person confirming)
- Send messages to any owner

What the front desk worker cannot do:

- Write medicine instructions (doctor only)
- Add or remove worker accounts
- See the activity history (manager only)

---

## The animal doctor's journey, step by step

```
Log in → See my patients → Open the pet's file → Examine the pet →
Write the visit notes → Add vaccines → Write medicine instructions →
Send the owner home with clear next steps
```

What the animal doctor can do:

- See all patients and open any pet's full history
- Write visit notes, add vaccines, add checkup findings
- Write medicine instructions — **the only one allowed to do this**
- Update the status of a medicine instruction (for example "ready" or "done")
- See and move the waiting line
- Look at the medicine list (to pick the right medicine and amount)

What the animal doctor cannot do:

- Change medicine stock counts
- Add or remove worker accounts
- See the activity history

---

## The manager's journey, step by step

```
Log in → Open the control area → Add or edit accounts →
Check the activity history → Change settings
```

What the manager can do:

- Everything the front desk worker can see (bookings, line, stock)
- Everything the doctor can see (patients, visit notes)
- Add new accounts for workers, doctors, and owners
- Change someone's job type (for example worker becomes doctor)
- Turn accounts on or off
- Open the activity history — the only one who can see it
- Change clinic settings

One small note: today, the manager's account still needs the doctor's help
to write medicine instructions, because that job is locked to the doctor
for safety. (There is a one-step fix for single-person clinics — see the
last section.)

---

## Who can do what — one simple table

| What needs doing | Owner | Front Desk | Doctor | Manager |
|---|:-:|:-:|:-:|:-:|
| Manage own pets | Yes | — | — | — |
| Book own visit | Yes | — | — | — |
| Approve and manage all bookings | — | Yes | Yes | Yes |
| Run the waiting line | view only | Yes | Yes | Yes |
| Write visit notes | — | Yes (help) | Yes | Yes |
| Write medicine instructions | — | — | Yes | Needs doctor |
| Handle medicine stock | — | Yes | view only | Yes |
| Scan medicine boxes | — | Yes | Yes | Yes |
| Add or remove accounts | — | — | — | Yes |
| See activity history | — | — | — | Yes |

---

## Our situation: only one clinic, one person doing everything

Right now the system is built for a bigger clinic where the counter person,
the doctor, and the manager are three different people. But our real
situation is simpler: **one small clinic, where one person does all three
jobs.**

### Should we merge the three into one account type?

**Short answer: no — keep the three as they are, and let the one person
use the manager account.**

Why this is better, in plain words:

1. **"Only the doctor gives medicine" stays true.** That rule protects the
   clinic — nobody can say "anyone wrote the medicine instructions." If we
   delete the doctor role, that safety story disappears, and the school
   panel will ask about it.
2. **The activity history stays honest.** The manager is the only one who
   can see who did what. If everyone becomes one blurry role, that safety
   list loses its meaning.
3. **Less work, less risk.** Merging means changing the app in many places
   and moving everyone's accounts around. Keeping things as they are means
   almost no changes.
4. **The manager account already opens everything.** One login can already
   see the bookings, the line, the patients, the stock, the accounts, and
   the history. Only one small lock remains (medicine instructions), and
   that has a one-step fix.

### What we suggest

1. The clinic's daily user logs in with the **manager account**. That's the
   one account that runs the whole day.
2. Ask the developer for the **one-step fix**: allow the manager account to
   also write medicine instructions when acting as the doctor. After that,
   one person can truly do everything.
3. In the school paper, write: *"The system supports 4 user types for a
   full-size clinic, but it is currently used in single-operator mode —
   one manager account runs bookings, line, records, stock, and
   management."* The panel keeps the full design, and the real clinic
   keeps the simple daily life.

---

*End of guide. If anything in the clinic's daily routine changes, this file
should be updated to match — it is the plain-words mirror of how the app
really behaves.*
