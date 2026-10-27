# Chapter 1 vs. System Alignment

Source: `Chapter 1 draft.lara.docx`, checked against the codebase on branch `feature/neumorphism-design` (2026-10-26).

**Verdict:** Mostly aligned. All four core objectives (1.1–1.4) are built. The gaps are field-level details, scope wording, and claims in the paper that the app does not yet back.

## Aligned

| Paper | System |
|---|---|
| 1.1 Appointment request and scheduling | `Appointment` entity: requested → confirmed → checked-in → completed, plus reschedule, cancel and no-show |
| 1.2 Records: history, consultation, diagnosis, treatment, vaccination, procedure | `MedicalRecord` (diagnosis, treatment, medications); types visit, vaccination, deworming, surgery, lab, prescription; separate `Vaccination` entity with next-due date; records are append-only |
| 1.3 Real-time queue | Firestore queue with position, estimated wait, and called / being served / done |
| 1.4 Inventory with scanning | Items, batches with expiry, stock transactions, ML Kit OCR that reads the expiry date, human confirmation before saving |
| Services: consultation, vaccination, deworming | All three are in `clinicServices` |
| Two users: pet owner and clinic | Roles `PET_OWNER` and `OWNER_ADMIN` |

## Mismatches

Mark each item: **P** = change the paper, **S** = change the system, **B** = change both, **X** = skip.

| # | Decision | Issue | Paper says | System has |
|---|---|---|---|---|
| 1 | **S** ✅ | Owner address | Index cards record the owner's address | `User` has name, email and phone only; no address |
| 2 | **S** ✅ | Pet markings | Records include markings | `Pet` has `color` and `microchipId`; no markings field |
| 3 | **S** ✅ | Same-name pets | The client's main interview complaint: pets with the same name are hard to find | Patient search shows species and breed, not the owner name, so same-name pets still look alike |
| 4 | **S** ✅ | Late arrivals | Observation: clients arrive late and the vet waits | `AppConstants.lateArrivalMinutes = 15` exists, but no logic uses it |
| 5 | **S** ✅ | Home service | Home servicing is a core part of the business | No "Home Service" option and no address capture for it |
| 6 | **S** ✅ | Species | Dogs and cats only | `PetSpecies` also allows bird, rabbit, reptile, other |
| 7 | **P** (confirm with client) | Service list | Consultation, vaccination, deworming | Also Dental Care, Minor Surgery, Diagnostic Test, Medicine Dispensing, Follow-up Checkup (confirm with the client) |
| 8 | **P** | "Clinic staff / personnel" | Refers to staff throughout | Demo has only Owner/Admin; vet and staff dashboards are hidden. The clinic is the vet and her husband, so the paper should say "clinic owner/admin" |
| 9 | **P** | Features built but not in the paper | Not mentioned | Notifications and reminders, queue priority (emergency/urgent), receipt and prescription scanning, low-stock and expiry alerts |
| 9a | **S** ✅ | Emergency queue priority | The clinic does not accept emergency cases | `QueuePriority.emergency` exists; rename or hide it |
| 10 | **P** | Empty sections | Scope and Delimitations, Project Significance, Conceptual Framework, Project Framework, Definition of Terms have headings only | Settle items 5–9 in Scope and Delimitations |

## Paper housekeeping

- [ ] The TOC puts Objectives before Client Profile, but the body has them the other way round.
- [ ] Figure labels are inconsistent: "Figure 1" (organizational structure) and "Figure B" (workflow).
- [ ] Table labels are inconsistent: List of Tables uses A/B/C, but the body uses "Table 1".
- [ ] The TOC page numbers for Chapters 2–3 overlap Chapter 1's (for example, Foreign Literature is on page 7).

## Done in the system (v1.0.2)

| # | Change |
|---|---|
| 1 | Pet owners can enter an optional **address** when they register and edit it on their Profile (`User.address`). |
| 2 | Pets have an optional **Markings** field on the pet form and pet detail page (`Pet.markings`). |
| 3 | The clinic's patient picker shows **Owner: name** under each pet. Search matches the pet name, the owner name or the markings. |
| 4 | A confirmed visit that has not checked in **15 minutes** after its time shows as **Late**. The detail page has a late notice and a **Mark as No-Show** button for the clinic. |
| 5 | **Home Service** is a bookable service. Picking it asks for a home address, prefilled from the owner's profile. The address shows on the appointment detail page. Home visits are never flagged late. |
| 6 | New pets can be **Dog** or **Cat** only. Older pets of another species keep their species when edited. |
| 9a | Queue triage offers **Urgent / Routine** only. Emergency appears only on entries that already have it. |

Tests: `test/features/appointments/chapter1_alignment_test.dart`.

## Still to do in the paper (team)

- 7: Confirm the extra services (Dental Care, Minor Surgery, Diagnostic Test, Medicine Dispensing, Follow-up Checkup) with the client, then list them in the paper or remove them from the app.
- 8: Replace "clinic staff / personnel" with "clinic owner/admin".
- 9: Add notifications, queue priority, receipt and prescription scanning, low-stock and expiry alerts, home service, and late / no-show handling to the scope.
- 10: Fill Scope and Delimitations, Significance, Conceptual Framework, Project Framework and Definition of Terms.
- The four paper housekeeping items above.
