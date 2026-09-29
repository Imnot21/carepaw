# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Flutter cross-platform app (iOS, Android, web, desktop builds). Design target is mobile-first (iOS/Android) with one unified design language across all surfaces and pages — not per-OS visual adaptation.

## Stack

Flutter 3.12+ / Dart 3.12+, BLoC (`flutter_bloc`), GoRouter, GetIt + Injectable, Firebase (Auth, Cloud Firestore, Cloud Messaging, Cloud Functions, App Check), `flutter_local_notifications`, `flutter_secure_storage`, `shared_preferences`. Custom neumorphic widget library in `lib/core/widgets/neomorphism/`. The codebase answers the stack; no greenfield choice needed.

## Users

- **Primary: Pet owners** — manage their pets' profiles, request appointments, check queue status, view medical records. Often in transit or at the clinic; mobile-first, task-oriented, emotionally invested in their pet's care.
- **Other confirmed audiences:** Veterinarians (patient records, visit documentation, prescriptions), clinic staff (appointments, check-ins, queue, inventory), administrators (user management, audit logs, settings).

## Product Purpose

CarePaw is a smart veterinary patient management system that connects pet owners, pets, veterinarians, and clinic staff in one platform. It modernizes clinic operations — appointment scheduling, real-time queue monitoring, digital medical records, medicine inventory, and OCR-assisted scanning — while keeping sensitive medical data secure, auditable, and historically intact. Success means veterinary care that is simpler, smarter, and more pet-friendly.

## Positioning

The only candidate system that unifies the full clinic journey — owner booking, staff queue operations, veterinary records, inventory, and OCR medicine/receipt scanning — with a mandatory human-in-the-loop verification step for OCR and a complete audit trail for sensitive operations. A neighboring product could copy individual features, but not the verified-scanning-plus-audit integrity model across every role in one system.

## Operating Context

- Fast-paced clinic floor: front-desk staff process check-ins and calls; veterinarians move between consult rooms; pet owners check status from mobile devices, often while traveling or waiting.
- Multi-role environment: the same appointment/queue/record is touched by owners, staff, and vets with different permissions.
- Sensitive material: medical records, prescriptions, and personal data require authorization checks, append-only history, and audit logging.
- Thesis/capstone context: proprietary project, no real clinic deployment data yet.

## Capabilities and Constraints

Confirmed capabilities:
- Role-based access: pet owner, veterinarian, staff, administrator.
- Pet profiles with ownership; species/breed info.
- Appointments: request, confirm, reject, check-in, complete — with strict valid state transitions.
- Real-time queue: backend-authoritative state, check-in, call-next, position tracking.
- Medical records: append-only health history, vaccinations, prescriptions; corrections/superseding instead of deletion.
- Inventory: medicine stock, batches, expiration tracking, fully traceable transactions.
- Scanning/OCR: receipt and medicine-box scanning; OCR output is never blindly trusted — human confirmation required.
- Notifications: appointment reminders, queue updates, prescription-ready, low-inventory alerts.
- Audit logging: security events and sensitive-operation tracking.

Durable constraints (from project rules):
- Never commit secrets; use environment variables / secure storage.
- Never trust OCR blindly; always require human confirmation.
- Never delete medical records; use corrections/superseding.
- Always check authorization for sensitive operations.
- Always use transactions for related database operations.
- Always validate input, client and server side.
- Always log sensitive operations.

Undecided: authentication flow details, notification delivery specifics, offline behavior.

## Brand Commitments

- Name: **CarePaw**.
- Stated concept: "Making veterinary care simpler, smarter, and more pet-friendly."
- Existing visual direction: neumorphism (see `PLAN_NEUMORPHISM.md` and `lib/core/widgets/neomorphism/`) — soft, tactile, single-hue surfaces. This is the incumbent identity to preserve or explicitly replace in new-work.
- No confirmed logo, typography, or asset commitments beyond the above.

## Evidence on Hand

- `README.md`, `CLAUDE.md`, `PLAN_NEUMORPHISM.md`, `README_Brag_Alternative.md`.
- Implemented feature scaffolding: pages, BLoC state management, Firestore repositories, domain entities, neumorphic widget library.
- Absences future work must not fabricate: real clinic data, testimonials, customer logos, benchmarks, pricing, deployment claims.

## Product Principles

1. **Care before paperwork** — every surface reduces friction for the person using it, whether owner, vet, or staff.
2. **Trust through verification** — machine output (OCR) and sensitive operations always pass through human confirmation and audit.
3. **Integrity of records** — medical history is append-only; inventory changes are fully traceable.
4. **One clinic, one system** — a unified design language and shared truth across all roles, pages, and surfaces; mobile-first.

## Accessibility & Inclusion

No product-specific accessibility requirement established yet; default to WCAG-conscious contrast, touch targets, and screen-reader semantics in all new work.
