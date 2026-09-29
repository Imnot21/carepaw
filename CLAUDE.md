# CarePaw

## Project Overview

CarePaw is a smart veterinary patient management system designed to modernize veterinary clinic operations.

The system connects:
- Pet owners with their pets' health information
- Veterinary staff with clinic operations
- Veterinarians with patient records
- Inventory management with scanning/OCR capabilities
- Appointments with queue management

## Core Modules

| Module | Description |
|--------|-------------|
| **Authentication** | User login, registration, roles, permissions |
| **User Management** | Pet owners, veterinarians, staff profiles |
| **Pet Management** | Pet profiles, ownership, species/breed info |
| **Appointments** | Scheduling, requests, status management |
| **Queue** | Check-in, queue position, real-time updates |
| **Medical Records** | Health history, vaccinations, treatments |
| **Inventory** | Medicine stock, batches, expiration tracking |
| **Scanning/OCR** | Receipt/medicine box scanning with validation |
| **Notifications** | Appointment reminders, queue updates, alerts |
| **Audit Logging** | Security events, sensitive operation tracking |

## Development Principles

### Architecture
- **Clean Architecture** - Separation of concerns with clear boundaries
- **SOLID Principles** - Maintainable, extensible code
- **Feature-first organization** - Code organized by feature, not layer

### Security
- Secure by default
- Authorization required for all sensitive operations
- Input validation at all levels
- No hardcoded secrets
- OCR output never trusted blindly

### Data Integrity
- Database constraints enforce business rules
- Transactions for related operations
- Medical records are append-only
- Inventory changes are fully traceable

### Code Quality
- Strong typing throughout
- No business logic in UI widgets
- Repository pattern for data access
- Comprehensive testing for critical paths

## Technology Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.12+ |
| Language | Dart 3.12+ |
| State Management | TBD (BLoC/Provider/Riverpod) |
| Database | TBD (SQLite/PostgreSQL via API) |
| Authentication | TBD (Firebase/Auth0/Custom) |

## Project Structure

```
lib/
├── app/                    # App configuration, routing, theme
│   ├── router/
│   └── theme/
├── core/                   # Shared infrastructure
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── security/
│   ├── storage/
│   ├── utils/
│   └── widgets/
├── features/               # Feature modules
│   ├── authentication/
│   ├── users/
│   ├── pets/
│   ├── appointments/
│   ├── queue/
│   ├── medical_records/
│   ├── inventory/
│   ├── scanning/
│   └── notifications/
└── main.dart
```

## Agent Usage

Specialized agents are available for specific tasks. Invoke the appropriate agent when:

| Task | Agent |
|------|-------|
| Architecture decisions | `01-carepaw-architect` |
| UI/UX implementation | `02-flutter-ui-ux` |
| Database design | `03-database-data-architect` |
| Security auditing | `04-carepaw-security` |
| Authentication/authorization | `05-authentication-authorization` |
| Appointment/queue logic | `06-appointment-queue-specialist` |
| Pet medical records | `07-pet-medical-records-specialist` |
| Inventory/OCR workflows | `08-inventory-ocr-specialist` |
| Notification system | `09-notification-specialist` |
| Testing strategy | `10-carepaw-qa` |
| Code review | `11-carepaw-code-reviewer` |
| Performance/accessibility | `12-performance-accessibility` |
| Documentation | `13-project-documentation` |
| Debugging/error fixing | `14-carepaw-debugger` |

## Implementation Status

| Module | Status |
|--------|--------|
| Project Setup | ✅ COMPLETE |
| Agent Structure | ✅ COMPLETE |
| Core Architecture | ✅ COMPLETE |
| Database Schema | ✅ COMPLETE |
| Authentication | 📋 PLANNED |
| Pet Management | 📋 PLANNED |
| Appointments | 📋 PLANNED |
| Queue Management | 📋 PLANNED |
| Medical Records | 📋 PLANNED |
| Inventory | 📋 PLANNED |
| Scanning/OCR | 📋 PLANNED |
| Notifications | 📋 PLANNED |

## Key Workflows

### Pet Owner Journey
```
Register/Login → Add Pet → Request Appointment → 
Receive Confirmation → Check Queue Status → View Pet Records
```

### Veterinary Staff Journey
```
Login → Manage Appointments → Process Check-ins → 
Manage Queue → Handle Inventory → Process Scans
```

### Veterinarian Journey
```
Login → View Assigned Patients → Open Records → 
Document Visit → Create Prescriptions → Update Records
```

## Important Rules

1. **Never commit secrets** - Use environment variables
2. **Never trust OCR blindly** - Always require human confirmation
3. **Never delete medical records** - Use corrections/superseding
4. **Always check authorization** - Every sensitive operation
5. **Always use transactions** - For related database operations
6. **Always validate input** - Both client and server side
7. **Always log sensitive operations** - Audit trail required
8.When I ask you to install, configure, update, or remove something in the development environment, do not merely explain how to do it. First determine the appropriate CLI command or available tool, then execute it. If the first command fails, inspect the error and determine the correct command instead of giving up. Only ask me for clarification when the request genuinely requires information you cannot determine.
## Getting Started

1. Ensure Flutter SDK 3.12+ is installed
2. Clone the repository
3. Run `flutter pub get`
4. Configure environment (see `.env.example`)
5. Run `flutter run`

## Documentation

- [Architecture Documentation](.claude/docs/CAREPAW_ARCHITECTURE.md)
- [Agent Index](.claude/agents/)

---

*CarePaw - Smart Veterinary Patient Management System*
