# CarePaw Session Memory

## 2026-09-29 — Soft Clinic Design System Build + Router Wiring + Neumorphic Component Completion

### What We Did

**Init** — Captured product truth in `PRODUCT.md`:
- Platform: adaptive (mobile-first iOS/Android, unified design language)
- Primary user: pet owner
- Stack: Flutter 3.44.9 / Dart 3.12.2, BLoC, GoRouter, Firebase, google_fonts
- Scope: all pages, unified design

**Direction** — "Soft Clinic" (user-pinned, beat the concept-seed roll d8d9fc36):
- Neumorphism owns material & controls (soft dual-shadow extrusion)
- Organic owns shape & motion (flowing radii, blob avatars, pill buttons)
- Minimalist owns layout & type (whitespace, one accent, Nunito headlines)
- Challengers weighed: all declined/competitive; two raises folded in (achromatic content fields, one warm accent per screen)

**Design Tokens** — Refined in `lib/app/theme/`:
- `app_colors.dart` — warm bone canvas #F7F4EF, terracotta #E27D60, warm charcoal dark #1C1917
- `app_text_styles.dart` — Nunito display/headlines, system body face
- `app_theme.dart` — Material 3, light + dark, wired to refined tokens
- `theme_colors.dart` — NEW: ThemeColors resolver (was missing, caused 100+ errors)
- `pubspec.yaml` — added google_fonts: ^6.2.1

**Widget Library** — Elevated in `lib/core/widgets/neomorphism/`:
- `neu_shapes.dart` — NEW: NeuShape system (cardFlow, squircle, blob, blobSm, pillRadius, navFlow, pawPrint, leaf)
- `neu_container.dart` — added shape support, ShapeDecoration, organic contours
- `neu_card.dart` — flowing cardFlow contours by default
- `neu_button.dart` — pill shapes, refined radii
- `neu_avatar.dart` — blob avatars with custom clipper
- `neu_bottom_nav.dart` — organic navFlow pill
- `neu_chip.dart` — pill contours
- `neu_icon_button.dart` — organic blob shapes
- `index.dart` — exports neu_shapes

**New Neumorphic Components** — Added to `lib/core/widgets/neomorphism/`:
- `neu_dialog.dart` — `NeuDialog`, `NeuConfirmDialog`, `NeuBottomSheet` (replaces AlertDialog, Dialog, showModalBottomSheet)
- `neu_divider.dart` — `NeuDivider`, `NeuVerticalDivider`, `NeuSectionDivider` (replaces Divider)
- `neu_fab.dart` — `NeuFAB`, `NeuFAB.mini`, `NeuFAB.extended`, `NeuFABSpeedDial` (replaces FloatingActionButton)

**Router Wiring** — Replaced 8 placeholder routes with real feature pages:
- `/medicalRecords` → `MedicalRecordListPage` (via `_MedicalRecordsLoader` with petId query)
- `/staffDashboard/appointments` → `AppointmentListPage`
- `/staffDashboard/inventory` → `InventoryListPage`
- `/staffDashboard/scanning` → `ScanListPage`
- `/vetDashboard/patients` → `PetListPage`
- `/vetDashboard/patients/:id` → `PetDetailPageWithBloc`
- `/vetDashboard/records` → `MedicalRecordListPage` (with petId query)
- `/notifications` → `NotificationListPage`

**Pages Refined** (28/28 pages now fully compliant with Soft Clinic system):
- Auth: login, register, forgot_password, reset_password
- Home: home_page (primary surface), staff_dashboard_page, vet_dashboard_page, admin_dashboard_page, admin_settings_page
- Pets: pet_list, pet_form, pet_detail
- Appointments: appointment_list, appointment_form, appointment_detail, staff_queue_page
- Queue: queue_page, staff_queue_page
- Medical Records: medical_record_list, medical_record_form, medical_record_detail
- Inventory: inventory_list, inventory_form, inventory_detail
- Scanning: scan_list, scan_detail, scan_camera
- Notifications: notification_list, notification_detail, notification_settings
- Users: profile_page, admin_user_management_page
- Audit: admin_audit_page

**Full Neumorphic Migration** — All 12 partially-compliant pages brought to full compliance:
- Replaced 12 `FloatingActionButton` → `NeuFAB`
- Replaced 28 `AlertDialog`/`Dialog` → `NeuDialog`/`NeuConfirmDialog`
- Replaced 35 `Divider` → `NeuDivider`
- Replaced 7 `TabBar` → `NeuChip` tabs
- Replaced 3 `Switch` → `NeuSwitch`
- Replaced 10 `DropdownButton`/`SegmentedButton` → `NeuChip` selections
- Replaced 5 `IconButton` → `NeuIconButton`
- Replaced 40+ `BoxDecoration` icon containers → `NeuContainer`
- Replaced `showModalBottomSheet` → `NeuBottomSheet` (6 instances)

**Verification**:
- flutter analyze: zero errors, zero warnings
- flutter test: 17/17 pass
- flutter build web: succeeds
- DESIGN.md: written at project root

### Key Decisions
- Color strategy: Restrained (neutrals + one terracotta accent)
- Typography: Nunito for display/headlines, system face for body
- Shape: organic flowing radii, no perfect circles for avatars
- Build order: pet owner flow first, then staff/vet surfaces
- Element allocation: neumorphism=material, organic=shape, minimalist=layout

### How to Continue
- Run `flutter run` to see the app
- Home page is the primary surface — start there
- All pages use Neu* widgets from `lib/core/widgets/neomorphism/`
- All colors via `ThemeColors.x(context)` — never raw AppColors in widgets
- DESIGN.md documents the full visual world
- Surface brief at `.impeccable/surfaces/home.md`
- PRODUCT.md has product truth

### File Map
- `PRODUCT.md` — product truth
- `DESIGN.md` — visual world documentation
- `.impeccable/surfaces/home.md` — surface brief with direction contract
- `lib/app/theme/` — colors, text styles, theme, theme_colors
- `lib/core/widgets/neomorphism/` — 16 widget files + shapes (neu_dialog, neu_divider, neu_fab added)
- `lib/features/` — all feature pages refined
- `lib/app/router/app_router.dart` — all 8 placeholder routes wired