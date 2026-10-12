# CarePaw — Panelist Questions & Answers (Defense Prep)

> I read Chapter 1 (`g-chapter-1.docx`) and the built app, then asked the
> hard questions a panelist would ask. Each answer is short enough to say
> out loud in under a minute.

---

## About the title and the idea

### 1. "What is so SMART about your system?"
The smart is the combination, not one magic feature: a waiting line that
updates on every phone by itself, a camera that reads medicine boxes (with a
person always confirming), records no one can secretly edit, and stock/expiry
watching that warns before things run out. The old clinic ran on a logbook,
verbal queue updates, and memory — the system replaces 4 manual channels
with one live, self-checking platform. Note the honest limit in our scope:
no auto-diagnosis; the system never pretends to replace the vet's judgment.

### 2. "Why a mobile app? Why not just a computer at the counter?"
Two users, two places. Owners check bookings and their line number from home
or while traveling; staff run the line from the clinic floor. A counter-only
computer serves one of them. Mobile serves both, and the queue feature only
works if the owner carries it in their pocket.

### 3. "Why DocMyk's PILA VET HUB specifically? Why not a generic system?"
The scope says it plainly: built for one real clinic's actual workflow
(counters, paper charts, verbal queues, manual stock). A generic system would
be guessing; ours came from an interview with the owner/vet, observation of
daily work, and review of their paper records. Other clinics can adopt it
later, but version 1 fits Pila Vet Hub exactly.

---

## About the users and roles

### 4. "Your paper says Pet Owner and Owner/Admin. Does the app match?"
Yes — exactly. The app has the same 2 sides: one owner login, one
Owner/Admin login running the whole clinic (bookings, line, records,
vaccines, deworming, medicine instructions, stock, scanning). Earlier builds
had extra Staff/Vet/Admin roles; those were removed to match Chapter 1 (a
backup copy is kept). The paper's own org chart shows one owner/boss above
front desk, vet staff, and clinic staff — our Owner/Admin covers all three
duties.

### 5. "If one Owner/Admin does everything, where is your security?"
Doing everything is not seeing everything blindly. Owners only see their own
pets, bookings, and records. Clinic writes are gated per collection
(appointments, records, queue, stock), medicine instructions are vet-locked,
and the activity history is manager-side only and can never be edited. Plus
every login needs an account — no anonymous access anywhere.

### 6. "What stops a pet owner from seeing another owner's pets?"
Ownership checks on every read and write: pets, bookings, and records carry
the owner's ID, and the database compares it with the logged-in user before
returning anything. The queue screen is the one exception — it shows line
numbers only, no names or pet details of other people.

---

## About scope and objectives

### 7. "Your scope excludes everything outside 4 areas — but you built audit logs and account management. Isn't that out of scope?"
No. Those aren't clinic services; they're the paper's own quality
requirements made real: security, privacy, data integrity, maintainability.
Audit logs prove *who did what*; account controls prove *only the right
people could do it*. The 4 service areas (bookings, records, queue, stock)
are the scope; these two are the locks on the door.

### 8. "Objective 1.2 promises digital health records 'including procedures.' Where are procedures in the app?"
Procedures are recorded as visit-note entries (findings, treatment,
procedure done, follow-up) inside the pet's history, same as consultations
and treatments. If the panel wants the word "procedure" visible, we add it as
a record-type label — one afternoon, no redesign.

### 9. "Objective 1.4 promises scanning AND recognition. Do you do recognition or just photos?"
Both steps: the camera captures the image, recognition reads the medicine
text into the form, and the Owner/Admin verifies before saving. Recognition
assists; the person decides — exactly what the scope requires.

### 10. "Your queue 'depends on timely data entry' (your own limitation). Doesn't that break 'real-time'?"
Real-time means *propagation* is instant: once staff tap "call next," every
phone updates immediately with no refresh. Data entry timing is a people
factor, true of any system, and we state it openly in the delimitations.
The improvement over the old process (owner must ask staff verbally) stands
regardless.

---

## About the old process and the change

### 11. "Walk me through the old appointment process vs yours in 30 seconds."
Old: owner calls/texts/messages/walks in → staff handwrites it in a logbook
→ changes mean crossing out and rewriting → confirmations by chat. New:
owner taps a booking with pet, date, reason → clinic approves in one tap →
status, line, and messages follow automatically. Same steps, zero paper,
zero re-encoding.

### 12. "Paper charts worked for years. What exactly was broken?"
Four things from our observation: bookings scattered across calls, texts,
social media, and walk-ins; charts that must be found, carried, and refiled
by hand; queues announced by shouting or asking; stock counted by eye
periodically. Nothing was "broken" — it just didn't scale and every step
depended on one person's memory.

### 13. "What happens to the old paper records?"
They stay as the historical archive. New visits go digital from day one.
If the clinic wants, old charts can be summarized into the new history as
opening notes — but the paper never claims back-encoding; that's a clinic
decision, not a system requirement.

---

## About method and evaluation

### 14. "Why Agile Scrum for a fixed-scope capstone?"
Because the client could react. Sprints (users+pets → bookings+queue →
records → stock+scan) each ended with something the owner could tap and
correct early. Fixed scope set the *destination*; Scrum set the *route* —
and the sprint review/client feedback loop is documented in our framework.

### 15. "How will you prove the system is 'acceptable' (Objective 2)?"
By the paper's own 5 measures: functionality (does each requirement work),
usability (can owners and the Owner/Admin actually use it), performance
(response time on records/queue/stock screens), reliability (consistent
behavior in normal use), and security (unauthorized access blocked). Client
plus IT-expert evaluation forms are already in the appendices.

### 16. "Who evaluates — the owner alone? Isn't that biased?"
Two groups: the client (fitness for real work) and IT experts (technical
quality) — separate forms, separate appendices. Owner feedback proves
usefulness; expert review proves correctness. Neither alone is enough.

---

## Trap questions (and calm answers)

### 17. "Can your system diagnose a sick dog from symptoms?"
No, and it never will. The scope excludes automated diagnosis and treatment
decisions. It records the vet's diagnosis; it doesn't make one. Saying no
here is a strength — it shows we know the boundary between tool and
professional.

### 18. "What if two staff update the same queue at the same time?"
Queue state lives in one shared database, not on each phone — the last
confirmed action wins and every screen re-syncs to it. No divergent copies,
no merging. That's precisely why the design dropped the local-database idea
(see the project's change request record).

### 19. "Internet dies in Pila during a storm. Your system dies too?"
Honestly: live features (bookings sync, queue updates) need internet — the
system requirements say so openly. The old paper process is the fallback
that day, same as any online system. Offline mode was never a stated
requirement; the clinic has connectivity through the operating day.

### 20. "After graduation, who maintains this?"
The non-functional requirements cover it: maintainability by design
(organized code, one database, documented roles), plus the manager-side
settings and account controls so the clinic runs daily ops without a
developer. Handover = the Owner/Admin account, the docs folder, and this
defense.

---

*Tip: answer, then demo. Every answer above has a 30-second live demo
behind it — offer it before they ask for it.*
