# CarePaw Architecture Documentation

## System Overview

CarePaw is a smart veterinary patient management system designed to replace inefficient manual processes in veterinary clinics with digital, integrated workflows.

### Problem Statement

Veterinary clinics currently rely on:
- Paper-based pet records that are hard to search and maintain
- Manually handled appointment requests without clear status tracking
- Unclear waiting queues causing patient anxiety
- Manual medicine inventory entry prone to errors
- Fragmented communication between staff and pet owners

### Solution

CarePaw provides an integrated platform that:
- Digitizes pet medical records with full history
- Streamlines appointment requests and scheduling
- Provides real-time queue monitoring
- Automates medicine inventory with OCR-assisted entry
- Delivers timely notifications to all stakeholders

## High-Level Architecture

### Architectural Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  Flutter Widgets | State Management | Navigation | Theme    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                        │
│  Use Cases | Application Services | DTOs | State Objects    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                           │
│  Entities | Repository Interfaces | Business Rules | Values │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    DATA/INFRASTRUCTURE LAYER                 │
│  Repository Implementations | Data Sources | API | Database │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Rule

- Dependencies point **downward only**
- Upper layers depend on lower layers
- Lower layers **never** depend on upper layers
- Domain layer has **no external dependencies**

## Module Overview

### Core Features

#### 1. Authentication Module
**Responsibility**: User identity and access control

**Components**:
- Login/Registration screens
- Session management
- Token handling
- Password reset flow

**Key Entities**:
- User
- Session
- Role
- Permission

**Access Control**:
```
Pet Owner   → Own data, own pets
Veterinarian → Assigned patients, medical records
Staff       → Appointments, queue, inventory
Admin       → User management, audit logs, settings
```

---

#### 2. Pet Management Module
**Responsibility**: Pet profiles and ownership

**Components**:
- Pet list/detail views
- Pet creation/editing
- Ownership management
- Weight tracking

**Key Entities**:
- Pet
- PetOwner
- WeightRecord

**Relationships**:
```
User (Pet Owner) ──< Pet ──< WeightRecord
Pet ──< MedicalRecords
Pet ──< Vaccinations
```

---

#### 3. Appointment Module
**Responsibility**: Scheduling and appointment management

**Components**:
- Appointment request form
- Scheduling calendar
- Status management
- Cancellation/rescheduling

**Key Entities**:
- AppointmentRequest
- Appointment
- AppointmentStatus (enum)

**State Machine**:
```
REQUESTED → CONFIRMED → CHECKED_IN → QUEUED → IN_PROGRESS → COMPLETED
    ↓           ↓           ↓           ↓
 REJECTED   CANCELLED   CANCELLED   CANCELLED
```

---

#### 4. Queue Module
**Responsibility**: Real-time queue management

**Components**:
- Queue display
- Check-in process
- Position tracking
- Call next functionality

**Key Entities**:
- QueueEntry
- QueueStatus (enum)

**Flow**:
```
Check-in → Create QueueEntry → Assign Position → 
Update Position → Call → Start Service → Complete
```

---

#### 5. Medical Records Module
**Responsibility**: Pet health history

**Components**:
- Visit records
- Vaccination tracking
- Treatment documentation
- Clinical notes

**Key Entities**:
- PetMedicalRecord
- Vaccination
- Treatment
- Prescription

**Immutability Rule**:
- Medical records are **append-only**
- Corrections create new records with reference to original
- Deletion is **not allowed**

---

#### 6. Inventory Module
**Responsibility**: Medicine stock management

**Components**:
- Medicine catalog
- Batch management
- Stock operations
- Expiration tracking

**Key Entities**:
- Medicine
- InventoryBatch
- InventoryTransaction

**Transaction Integrity**:
```
Every stock change:
├── Record quantity before
├── Record quantity change
├── Record quantity after
├── Reference to performer
├── Reason for change
└── Immutable record
```

---

#### 7. Scanning/OCR Module
**Responsibility**: Image-based data entry assistance

**Components**:
- Image capture
- OCR processing
- Data extraction
- Validation/confirmation

**Key Entities**:
- ScanRecord
- ScanStatus (enum)

**Golden Rule**:
```
OCR output is NEVER automatically trusted.

SCAN → OCR → VALIDATE → CONFIRM → UPDATE
         ↑
    Human verification required
```

---

#### 8. Notification Module
**Responsibility**: User communication

**Components**:
- Notification creation
- Preference management
- Delivery tracking
- History

**Key Entities**:
- Notification
- NotificationPreferences
- NotificationType (enum)

**Notification Types**:
- Appointment reminders
- Queue updates
- Vaccination due
- Inventory alerts
- System announcements

---

## Data Flow

### Appointment Request Flow
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│Pet Owner │────>│ Request  │────>│  Staff   │
└──────────┘     │  Form    │     │ Review   │
                 └──────────┘     └────┬─────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ↓                  ↓                  ↓
             ┌──────────┐       ┌──────────┐       ┌──────────┐
             │ CONFIRM  │       │ REJECT   │       │ CONTACT  │
             └────┬─────┘       └──────────┘       └──────────┘
                  │
                  ↓
             ┌──────────┐
             │ Scheduled│
             │ Appointment│
             └──────────┘
```

### Queue Flow
```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ CONFIRMED│────>│ CHECK-IN │────>│  QUEUED  │────>│IN_PROGRESS│
│Appointment│    │  Process │     │  Entry   │     │  Service │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ↓                  ↓                  ↓
             Position #1         Position #N         Called
             (Wait: 5min)        (Wait: 30min)       (Now serving)
```

### Inventory Stock-In Flow
```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Scan    │────>│   OCR    │────>│ Validate │────>│  Confirm │
│  Image   │     │ Extract  │     │  Data    │     │  Human   │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
                    ┌───────────────────────────────────┘
                    ↓
             ┌──────────┐     ┌──────────┐
             │ Create   │────>│ Create   │
             │  Batch   │     │Transaction│
             └──────────┘     └──────────┘
```

## Security Model

### Authentication
- Email/password authentication
- Secure password hashing (bcrypt/Argon2)
- Session-based or JWT tokens
- Rate limiting on login attempts
- Account lockout after failed attempts

### Authorization
- Role-Based Access Control (RBAC)
- Resource ownership verification
- Permission checks on every sensitive operation

### Data Protection
- HTTPS for all communications
- Sensitive data encrypted at rest
- Secure token storage (flutter_secure_storage)
- No secrets in source code

### Audit Logging
Events logged:
- Authentication events (success/failure)
- Permission changes
- Medical record access
- Inventory adjustments
- Administrative actions

## Database Overview

### Core Tables

| Table | Purpose |
|-------|---------|
| users | User accounts and authentication |
| roles | User role definitions |
| user_profiles | Extended user information |
| pets | Pet profiles |
| medical_records | Visit documentation |
| vaccinations | Vaccination history |
| appointments | Scheduled visits |
| queue_entries | Active queue |
| medicines | Medicine catalog |
| inventory_batches | Stock batches |
| inventory_transactions | Stock changes |
| scan_records | OCR processing records |
| notifications | User notifications |
| audit_logs | Security audit trail |

### Key Relationships
```
users ──< pets ──< medical_records
                 ──< vaccinations

appointments ─── queue_entries (1:1)
appointments ─── pets (N:1)

inventory_batches ──< inventory_transactions
medicines ──< inventory_batches
```

## Technology Decisions

### Flutter Framework
**Why Flutter**: 
- Cross-platform (mobile, web, desktop)
- Single codebase
- Rich UI components
- Good performance
- Strong typing with Dart

### State Management
**Decision**: TBD (recommend BLoC or Riverpod)
**Rationale**:
- Clear separation of UI and logic
- Testable business logic
- Reactive updates
- Good tooling support

### Database
**Decision**: TBD (SQLite local + API for sync, or remote-first)
**Considerations**:
- Offline capability needs
- Data volume
- Multi-device sync requirements
- Clinic infrastructure

### Backend
**Decision**: TBD
**Options**:
- Firebase (quick setup, managed)
- Custom API (full control, self-hosted)
- Supabase (open-source Firebase alternative)

## Testing Strategy

### Test Pyramid
```
           /\      E2E Tests
          /  \     (Critical user journeys)
         /────\
        /      \   Integration Tests
       /────────\  (Feature workflows)
      /          \
     /────────────\ Unit Tests
    /              \(Business logic, utilities)
```

### Coverage Targets
- Domain layer: 90%
- Application layer: 80%
- Data layer: 70%
- Presentation layer: 60%

### Critical Path Testing
- Authentication flows
- Appointment state transitions
- Queue operations
- Medical record creation
- Inventory transactions
- OCR validation flow

## Implementation Phases

### Phase 1: Foundation ✅
- Project structure
- Agent organization
- Architecture documentation

### Phase 2: Core Infrastructure 📋
- Routing
- Theme/design system
- Error handling
- Core utilities

### Phase 3: Database 📋
- Schema design
- Repository interfaces
- Migrations strategy

### Phase 4: Authentication 📋
- Login/Registration
- Session management
- Role-based access

### Phase 5: Pet Management 📋
- Pet profiles
- Owner association

### Phase 6: Appointments 📋
- Request workflow
- Scheduling
- Status management

### Phase 7: Queue 📋
- Check-in
- Position tracking
- Real-time updates

### Phase 8: Medical Records 📋
- Visit documentation
- Vaccinations
- Treatments

### Phase 9: Inventory 📋
- Medicine catalog
- Stock management
- Transactions

### Phase 10: Scanning/OCR 📋
- Image capture
- OCR integration
- Validation workflow

### Phase 11: Notifications 📋
- In-app notifications
- Preference management

### Phase 12: Testing & Polish 📋
- Comprehensive testing
- Performance optimization
- Accessibility audit

### Phase 13: Documentation 📋
- API documentation
- User guides
- Thesis preparation

## Design Decisions Log

### ADR-001: Clean Architecture
**Status**: Accepted
**Decision**: Use Clean Architecture with four layers
**Rationale**: Separation of concerns, testability, maintainability

### ADR-002: Feature-First Organization
**Status**: Accepted
**Decision**: Organize code by feature, not layer
**Rationale**: Better discoverability, feature isolation, scalable

### ADR-003: Immutable Medical Records
**Status**: Accepted
**Decision**: Medical records are append-only
**Rationale**: Audit trail, data integrity, legal requirements

### ADR-004: Human-Verified OCR
**Status**: Accepted
**Decision**: OCR output requires human confirmation
**Rationale**: Data accuracy, error prevention, accountability

## Glossary

| Term | Definition |
|------|------------|
| Pet Owner | User who owns pets and requests appointments |
| Veterinarian | Medical professional who treats animals |
| Staff | Clinic staff managing operations |
| Queue Entry | Record of a pet's position in the waiting queue |
| Batch | Specific quantity of medicine with expiration date |
| Transaction | Record of any inventory quantity change |
| OCR | Optical Character Recognition - extracting text from images |

---

*Last Updated: 2026-08-18*
*Document Owner: CarePaw Architecture Team*
