# Role Alignment Plan — Match Chapter 1 (Owner + Owner/Admin) — EXECUTED

> Goal: the app's roles match the thesis paper (Pet Owner + Owner/Admin).
> **Status: done.** Final decision went further than this plan's draft: the
> old Staff/Veterinarian/Admin roles were **deleted** (not kept as reserve),
> because the paper's scope is one clinic. The full big-clinic version is
> preserved as a separate backup copy / repository (`carepaw`), while this
> copy (`carepawdemo`) is the paper build. Non-paper screens (audit, users,
> settings) were hidden from tabs, not deleted. The phase table below is
> kept as the execution record.

---

## 1. Where we are vs where the paper is

- **Paper (Chapter 1):** 2 sides — Pet Owner, Owner/Admin. One clinic-side
  account does bookings, records, line, and stock.
- **App today:** 4 roles — `PET_OWNER`, `STAFF`, `VETERINARIAN`, `ADMIN`.
  Built for a big clinic with separate counter, doctor, and boss.
- **Target:** 2 active roles — `PET_OWNER` + new `OWNER_ADMIN`. The 3
  big-clinic roles stay in the code and rules, marked reserved, still
  working, just hidden from daily use and account creation.

## 2. Principles (so we don't break anything)

1. **Add, don't delete.** New role value added; no enum value removed, no
   screen deleted, no rule deleted.
2. **Owner/Admin can do everything the clinic needs**, including writing
   medicine instructions (the one thing ADMIN can't do today).
3. **Old roles keep working.** An account still tagged STAFF/VET/ADMIN logs
   in and behaves exactly as today — they're the backup for a bigger
   future clinic.
4. **Thesis wording stays true.** After this, demo = 2 logins, paper = 2
   sides, app = 2 active roles.

## 3. The plan, step by step

### Phase 1 — New Owner/Admin role (the core change)

| Step | File | Change |
|---|---|---|
| 1.1 | `lib/features/authentication/domain/entities/user.dart` | Add `ownerAdmin('OWNER_ADMIN')` to `UserRole`; display name `Owner/Admin`; add `isOwnerAdmin` helper (same style as `isStaff` etc.). Keep staff/veterinarian/admin untouched, mark them `// RESERVE: big-clinic roles` in a comment |
| 1.2 | `firestore.rules` | Add `isOwnerAdmin()` + extend the clinic union: `isClinicStaff()` stays, new `isClinicOperator()` = staff/vet/admin/**ownerAdmin**. Grant ownerAdmin: appointments full, queue create/update, medical create, **prescriptions create + status update**, inventory read/write, scans, notifications to anyone, users manage, audit read. Keep every old rule line working |
| 1.3 | `lib/app/shell/role_tabs.dart` | Add `_ownerAdmin` tab set: Dashboard · Appointments · Queue · Patients · Records · Inventory · Scanning · Users · Audit · Profile. `forRole(ownerAdmin)` returns it. Old tab sets untouched |
| 1.4 | `lib/app/router/app_router.dart` | `_getHomeRouteForRole(ownerAdmin)` → new clinic home (see 1.5). Guards: ownerAdmin passes `/staff/*`, `/vet/*`, `/admin/*` (same as admin today). Keep old guards |
| 1.5 | New `lib/features/home/presentation/pages/clinic_dashboard_page.dart` | One Owner/Admin home combining today's three dashboards: today's numbers + line preview (from staff), patient/record shortcuts (from vet), accounts + history entry (from admin). Reuse existing section widgets, don't rewrite them |
| 1.6 | `admin_user_management_page.dart` + `user_management_bloc.dart` | Account creation offers **Pet Owner** and **Owner/Admin** only. Staff/Vet/Admin creation moved under a labeled "Reserve (big clinic)" section — still possible, just clearly marked future-use |
| 1.7 | `register_page.dart` | No change (still pet-owner only). Confirm in passing |
| 1.8 | Dashboard guards | `staff_dashboard_page.dart` (`isStaffOrAdmin`), `vet_dashboard_page.dart` (`isVetOrAdmin`), `admin_dashboard_page.dart` (`== admin`) each also accept `ownerAdmin` — one condition added per file |

### Phase 2 — Data + accounts (no migration of old data needed)

| Step | Action |
|---|---|
| 2.1 | Create the real clinic account: one `OWNER_ADMIN` user for DocMyk's PILA VET HUB (Ma Mikha De La Cruz-Abenido). This is the daily-use login |
| 2.2 | Existing STAFF/VET/ADMIN test accounts (if any) stay as they are — they are the reserve, already working |
| 2.3 | No bulk rewrite of the `users` collection: old role values remain valid in code and rules |

### Phase 3 — Verify (prove both present and reserve work)

| Step | Check |
|---|---|
| 3.1 | Owner/Admin login → clinic home opens; can approve bookings, run the line, write visit notes **and** medicine instructions, update stock, confirm scans, add accounts, open activity history |
| 3.2 | Pet owner login → unchanged journey (pets, bookings, line, history, messages) |
| 3.3 | Reserve check → a STAFF account and a VETERINARIAN account still log in to their old homes and old tabs with old permissions |
| 3.4 | Rules check → owner can't reach clinic writes; old roles behave exactly as before; audit logs still manager-side only |
| 3.5 | Deep-link check → `/medical-records/:id` + `/new` 404 fix (from APP_FLOWCHART §8) done alongside, since the doctor flow touches it |

### Phase 4 — Paper + docs (one sitting)

| Step | Action |
|---|---|
| 4.1 | Chapter 1: no role changes needed — it already says Owner/Admin. Add one line that the Owner/Admin side covers counter, clinical, and management duties (mirrors Figure 1 org chart) |
| 4.2 | Chapter 3/design: document the reserve roles in one paragraph — "Staff, Veterinarian, and Admin roles are implemented and retained for larger-clinic deployment; the current deployment activates Pet Owner and Owner/Admin." Panel sees foresight, not leftovers |
| 4.3 | Update `docs/SYSTEM_WORKFLOW.md`, `docs/APP_FLOWCHART.md`, `docs/APP_FEATURES.md`, `docs/ALIGNED.md` role tables: active = Owner + Owner/Admin; reserve noted once at the top of each |

## 4. What we are deliberately NOT doing

- Not deleting `STAFF` / `VETERINARIAN` / `ADMIN` from code, rules, or docs.
- Not rewriting old user accounts in the database.
- Not removing the three old dashboards — the new clinic home reuses them.
- Not changing the owner side at all.

## 5. Rollback (if anything goes wrong)

Every step is additive, so rollback = stop using the new value: keep logging
in with the old ADMIN account (still fully working), hide the Owner/Admin
picker option, and the app is exactly where it is today. Nothing to undo in
the database.

## 6. Done means

- [ ] `OWNER_ADMIN` exists in `UserRole`, rules, tabs, router, guards
- [ ] One real Owner/Admin account created for the clinic
- [ ] Demo runs on 2 logins matching Chapter 1
- [ ] Reserve roles still log in and work (spot-checked)
- [ ] Thesis Chapters 1–3 mention active vs reserve roles consistently
- [ ] The 4 docs files updated to the same story

---

*Related: `docs/ALIGNED.md` (why this is needed), `docs/APP_FLOWCHART.md §8`
(routing fixes to do alongside).*
