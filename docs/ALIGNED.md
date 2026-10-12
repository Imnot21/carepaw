# Is Our System Aligned With Our Thesis Paper? (Plain-Words Check)

> A simple check comparing Chapter 1 of the thesis paper
> (CarePaw for DocMyk's PILA VET HUB) with the app we actually built.
> No computer terms — just plain words.

---

## The short answer

**Mostly yes.** The 4 main jobs in the paper are all in the app. But there is
**1 big mismatch** and **3 small ones** to fix before the defense.

---

## What matches (the good news)

The paper asks for 4 main jobs. All 4 are in the app:

| Job in the paper | What the app does |
|---|---|
| 1. Booking and scheduling | Owners book visits; the clinic approves, moves, or cancels them |
| 2. Digital health records | Visit notes, vaccines, medicine instructions, full history per pet |
| 3. Live waiting line | Owners see their number; the clinic calls next, moves to room, finishes |
| 4. Medicine stock with camera scanning | Stock counts, expiry dates, scan a box, a person always double-checks |

These also match: pet profiles (name, animal, breed, age, weight), booking
and line messages, login with account types, search, works on phones, needs
internet, and the rule that **the machine's scan is never trusted alone**.

---

## Mismatch 1 WAS big, now FIXED: 2 sides in paper AND app

The paper only talks about **two sides**: the pet owners, and one
clinic-side account (called the Owner/Admin) that does everything — bookings,
records, line, and stock.

The app previously had **four** account types. It now has exactly the same
two: Pet Owner + Owner/Admin. Old roles deleted (backup copy kept).
Demo = 2 logins, paper = 2 sides. Status: **done**.

Also fixed since this check: pet sex field, service picker, Rescheduled
booking status, Cancelled line status, and deworming records — all paper
requirements that were missing. Status: **done**.

---

## Mismatch 2 (small): "change" old health notes

The paper says the clinic can "create, view, and change" health records. The
app **never lets anyone edit or delete an old note** — mistakes are fixed by
adding a new correction note on top.

**What to do:** fix the words, not the app. In the paper, explain that
"change" means *adding a correction note that replaces the old one, while
keeping the full history*. Then the app matches the paper, and the safety
rule stays.

---

## Mismatch 3 (small): different words for the same statuses

The paper says bookings are *waiting for approval / approved / moved /
done / cancelled* and the line is *waiting / being served / done /
cancelled*. The app uses slightly different words (*confirmed, checked-in,
called, in room…*). Same meanings, different labels.

**Update:** *Rescheduled* and *Cancelled* now exist in the app exactly as
named. For the rest, add one sentence in the paper showing which word
means which.

---

## Mismatch 4 (small): extra features not listed in the paper

The paper says anything outside the 4 main jobs is **not included**. But the
app also has: the activity history list, the accounts-management screen,
extra messages (medicine ready, low stock), and computer builds alongside
the phone app.

**What to do:** none of these break the paper — just don't present them as
main features. If asked, say they support the paper's own quality rules:
the activity history and account controls protect accounts and keep records
honest and private (the paper asks for exactly that).

---

## To-do list before the defense

1. ~~Demo with 2 logins only~~ — **done**, the app now has only 2 logins.
2. ~~Owner/Admin writes medicine instructions~~ — **done**.
3. Add one paragraph to the paper: record "changes" are correction notes on
   top of history.
4. Match the status words between paper and app (Rescheduled + Cancelled now
   exist; map the rest in one sentence).
5. Put the client's real name — DocMyk's PILA VET HUB, Pila, Laguna — in the
   app's own documents, so paper and project name the same client.

---

*Checked against: g-chapter-1.docx (Chapter 1 through objectives, scope, and
sprint plan) and the app as built. Date: 2026-10-12.*
