# CarePaw Simplification Plan

> Target: make CarePaw usable and manageable by **one or two people** (the vet-owner + spouse) who run the clinic as a Sunday hobby. **1 login role** (`Clinic Operator` = the vet-owner). Pet owners become **customer records she manages**, not logins.

Status: **PLAN ONLY — no code written yet.**

## Scope at a glance

- Codebase: **175 Dart files, ~42k lines**, no tests (`test/` is empty).
- Net effect: remove ~4 whole feature/screen clusters, collapse 4 dashboards → 1, rewrite auth/rules/nav around a single operator.
- Approx. **~8,000 lines removed**, **~20 files heavily edited**, **~4 new files**.

---

## 1. REMOVE (delete files + their routes/DI wiring)

| Area | Files | ~Lines | Why |
|---|---|---|---|
| Dashboards | `home/presentation/pages/staff_dashboard_page.dart`, `vet_dashboard_page.dart`, `admin_dashboard_page.dart`, `home_page.dart` | 1,982 | Replaced by one `clinic_dashboard_page.dart` |
| Admin user mgmt UI | `users/presentation/pages/admin_user_management_page.dart` + `user_management_bloc.dart` / `_event.dart` / `_state.dart` | 1,000 | No roles to manage; replaced by customer records |
| Audit feature | entire `features/audit/**` (page, bloc, repo, mapper, entity) | ~835 | Audit page dropped from app (backend writes only) |
| Scanning feature | entire `features/scanning/**` (camera/list/detail pages, bloc, repo, mapper, entity) | ~2,740 | Replaced by an OCR **capture inside Inventory** |
| Owner queue screen | `queue/presentation/pages/queue_page.dart` | 1,074 | `staff_queue_page.dart` becomes the single operator queue |
| Public registration | `authentication/presentation/pages/register_page.dart` (+ route) | 253 | No self-signup; operator seeded, customers are records |

Subtotal removed: **~7,884 lines across ~25 files.** Also delete their references in `app_router.dart`, `routes.dart`, `dependency_injection.dart`, `main.dart`.

---

## 2. CHANGE (edit in place)

| File | ~Lines | Change |
|---|---|---|
| `features/authentication/domain/entities/user.dart` | 115 | Collapse `UserRole` → `clinicOperator` (+ dormant `petOwner`) |
| `core/firebase/user_doc_mapper.dart` | 47 | Normalize role read/write to operator |
| `features/users/data/repositories/firestore_user_repository.dart` | 589 | Operator account + customer records; keep REST create/audit writes |
| `app/shell/role_tabs.dart` | 205 | Rewrite to **one** operator tab set |
| `app/router/app_router.dart` | 746 | Remove owner/staff/vet/admin groups; one guard; drop register route |
| `app/router/routes.dart` | 92 | Replace role paths with neutral `/clinic/*` |
| `core/di/dependency_injection.dart` | 197 | Unregister auditing/scanning/user-mgmt |
| `core/firebase/firestore_schema.dart` | 278 | Add customer fields; remove role-enum spread |
| `core/firebase/caller_scope.dart` | 43 | Operator owns all data → simplify/keep minimal |
| `core/storage/local_storage.dart` | 142 | Single-user session simplification |
| `firestore.rules` | 279 | `isOperator()` replaces `isStaff/isVeterinarian/isAdmin` |
| `appointments/presentation/pages/appointment_list_page.dart` | 827 | Strip owner-vs-clinic branches |
| `appointments/presentation/pages/appointment_form_page.dart` | 977 | Operator-only flow |
| `pets/presentation/pages/pet_list_page.dart` | 1,007 | Becomes **Patients** (customer + pet) |
| `pets/presentation/pages/pet_detail_page.dart`, `pet_form_page.dart` | 1,039 / 765 | Link pet → customer record |
| `medical_records/presentation/pages/medical_record_list_page.dart` | 748 | Remove broken `/vet/records` pet-required flow; fold prescriptions into records |
| `inventory/presentation/pages/inventory_list_page.dart`, `_form_page.dart`, `_detail_page.dart` | 740 / 644 / 1,132 | Simplify entry + add OCR capture entry point |
| `queue/presentation/pages/staff_queue_page.dart` | 1,038 | Rename to operator queue; states → `Waiting/Serving/Done` |
| `queue/domain/entities/queue_entry.dart` | 259 | Reduce status enum |
| `notifications/presentation/pages/notification_list_page.dart` | 880 | Simplify; single recipient (her) |
| `notifications/presentation/pages/notification_settings_page.dart` | 658 | Remove per-user prefs UI (single user) |
| `home/presentation/pages/admin_settings_page.dart` | 219 | Convert to clinic **Settings**, or remove |
| `app/theme/*` | — | Minor: no per-role theming needed |

---

## 3. KEEP AS-IS (core, minimal touch)

- All `core/widgets/neomorphism/**` (design system) — unchanged.
- `core/utils/validators.dart`, `formatters.dart`; error/exception/failure layers.
- `core/firebase/firebase_init.dart`, `firebase_auth_error_mapper.dart`, `firestore_id_sequence.dart`, `date_field_codec.dart`.
- `core/notifications/local_notification_service.dart`.
- Appointment / pet / medical-record / inventory / notification **domain + data layers** (entities, mappers, repositories) — logic stays; only UI/role branches change.
- `authentication/presentation/pages/login_page.dart`, `forgot_password_page.dart`, `reset_password_page.dart`, `auth_scaffold.dart` — keep (simplify copy).
- `features/users/presentation/pages/profile_page.dart` — keep.

---

## 4. ADD (new files)

| New file | Purpose |
|---|---|
| `home/presentation/pages/clinic_dashboard_page.dart` | Single operator dashboard (replaces 3) |
| `home/presentation/pages/clinic_customers_page.dart` | Customer directory (replaces admin user mgmt) |
| `inventory/presentation/pages/ocr_capture_page.dart` (or widget) | Photo → OCR → pre-fill name → **confirm** → save (never auto-trust) |
| `core/services/ocr_service.dart` | OCR provider wrapper (e.g. Google Cloud Vision) |

---

## 5. DEFER (build later)

- Optional **pet-owner login** (read-only: request appointment / check queue) — Phase 2.
- Full audit **viewer** — not now.

---

## 6. Feature triage (final)

| Module | Decision |
|---|---|
| Authentication | **Keep** — one operator login |
| User / Role management | **Drop** — no roles to manage |
| Customers + Pet management | **Keep** — merged into "Patients" |
| Appointments | **Keep** |
| Queue | **Keep, simplified** — `Waiting → Serving → Done` |
| Medical records | **Keep** — append-only, she manages |
| Inventory | **Keep** — simplified entry |
| Scanning / OCR | **Keep as an Inventory feature**: photo medicine → AI OCR → pre-fills name → **she confirms** → save stock |
| Notifications | **Keep, simplified** — in-app list, notification bell |
| Audit logging | **Backend writes kept; Audit page removed from nav** |
| Prescriptions | **Fold into Medical Records** (no separate module) |

### Operator navigation

```
Operator shell:  Dashboard · Appointments · Patients · Queue · Inventory
More → Records · Notifications · Settings (Profile, Clinic info)
Top bar → Notifications bell
```

---

## 7. Route mapping (old → new)

| Old | New |
|---|---|
| `/home`, `/staff`, `/vet`, `/admin` | `/clinic` |
| `/staff/appointments` | `/clinic/appointments` |
| `/vet/patients`, `/pets` | `/clinic/patients` |
| `/staff/queue`, `/queue` | `/clinic/queue` |
| `/staff/inventory` | `/clinic/inventory` |
| `/vet/records`, `/medical-records` | `/clinic/records` |
| `/staff/scanning` | removed (OCR inside inventory) |
| `/admin/users` | `/clinic/customers` |
| `/admin/audit`, `/register` | removed |

---

## 8. Permissions & data changes

- `firestore.rules`: one `isOperator()` helper; operator = full read/write. Append-only `medicalRecords` + `inventoryTransactions` preserved; `string()` cast kept.
- Roles: collapse three clinic roles → operator; existing users migrated (one-off Firestore update).
- Pets: `ownerId` → customer record id (not an Auth uid).

---

## 9. Recommended sequence

1. **Auth/role collapse** (user entity, mapper, rules, guard, migration).
2. **Shell/nav** (`role_tabs.dart`, `app_router.dart`, `routes.dart`).
3. **One dashboard + customers page** (add new, delete old 3 + user mgmt).
4. **Queue / pets / records relabel + simplify.**
5. **Inventory + OCR** (delete scanning, add capture).
6. **Notifications/settings simplify; delete audit UI.**
7. **QA** (no tests today → smoke-test critical paths) → `flutter analyze` → `flutter build web --release` → `firebase deploy`.

---

## 10. Risks / decide before coding

- **Customer model**: confirm customers are pure records (no login) — this drives the biggest data change.
- **OCR provider**: Google Cloud Vision (fits your Firebase project) vs placeholder stub.
- **Data migration**: existing STAFF/VET/ADMIN accounts must map to operator — need a one-off update script.
- **Deletion risk**: removing `home_page.dart` / owner routes touches `main.dart` + DI; do it in the router rewrite together.
