# CarePaw ERD - Paper-Matched (Plain Words + Mermaid)

> Client: DocMyk's PILA VET HUB, Pila, Laguna
> Paper: 2 sides only (Pet Owner + Owner/Admin), 4 jobs.
> This diagram removes old roles (VET/STAFF/ADMIN) and out-of-scope extras
> (AuditLog, user management, sync tables) so code matches Chapter 1.

## In plain words

- One **User** is either a **Pet Owner** or the single **Owner/Admin** who does
  counter + vet + boss work.
- An **Owner** owns many **Pets**. Each pet has sex, breed, weight.
- An **Appointment** is a booking for one pet, handled by the Owner/Admin
  (service picker: Consultation, Vaccination, Deworming...).
- A **QueueEntry** is the live waiting line for that appointment
  (waiting / called / in-room / done / cancelled).
- A **MedicalRecord** is the visit note (append-only, correction-note on top),
  plus **Vaccination** and **Prescription** (medicine instructions).
- **InventoryItem -> Batch -> Transaction** is the medicine stock.
- A **ScanRecord** is a camera scan of a box/receipt - machine never trusted
  alone, Owner/Admin must confirm.
- **Notification** is paper-only: appointment + queue messages.

## Mermaid

```mermaid
erDiagram
  User {
    int id PK
    string firebaseUid
    string email
    string fullName
    string phone
    string role "PET_OWNER | OWNER_ADMIN"
    bool isActive
  }
  Pet {
    int id PK
    int ownerId FK
    string name
    string species
    string breed
    string sex "MALE | FEMALE"
    date birthDate
    float weightKg
    string microchipId
  }
  Appointment {
    int id PK
    int petId FK
    int veterinarianId FK "OwnerAdmin"
    datetime scheduledAt
    string service "Consultation, Vaccination, Deworming..."
    string status "REQUESTED, CONFIRMED, RESCHEDULED, CANCELLED..."
    string reason
  }
  MedicalRecord {
    int id PK
    int petId FK
    int veterinarianId FK "OwnerAdmin"
    int appointmentId FK "nullable"
    string recordType "VISIT, VACCINATION, DEWORMING..."
    string title
    string diagnosis
    string treatment
    datetime recordedAt "append-only, no edit/delete"
  }
  Vaccination {
    int id PK
    int petId FK
    int veterinarianId FK "OwnerAdmin"
    string vaccineName
    datetime administeredAt
    datetime nextDueAt
  }
  Prescription {
    int id PK
    int medicalRecordId FK
    int petOwnerId FK
    int veterinarianId FK "OwnerAdmin"
    string medicationName
    string dosage
    string instructions "OwnerAdmin-writable"
  }
  QueueEntry {
    int id PK
    int appointmentId FK
    int position
    string status "WAITING, CALLED, IN_ROOM, COMPLETED, CANCELLED"
    string priority
    datetime checkedInAt
    string room
  }
  InventoryItem {
    int id PK
    string name
    string category
    string unit
    float currentStock
    float minStock
  }
  InventoryBatch {
    int id PK
    int inventoryId FK
    string batchNumber
    float quantity
    datetime receivedAt
    datetime expiresAt
  }
  InventoryTransaction {
    int id PK
    int batchId FK
    string type "IN, OUT, ADJUSTMENT"
    float quantityChange
    int performedBy FK "OwnerAdmin"
  }
  ScanRecord {
    int id PK
    string scanType "MEDICINE_BOX, RECEIPT..."
    string imagePath
    float confidenceScore
    string status "PENDING, CONFIRMED, REJECTED"
    int confirmedBy FK "OwnerAdmin, human must confirm"
  }
  Notification {
    int id PK
    int userId FK
    string type "APPOINTMENT_REMINDER, QUEUE_UPDATE only"
    string title
    bool isRead
  }

  User ||--o{ Pet : owns
  Pet ||--o{ Appointment : books
  User ||--o{ Appointment : "handles (OwnerAdmin)"
  Appointment ||--o| QueueEntry : "checks-in-to"
  Pet ||--o{ MedicalRecord : has
  Appointment ||--o{ MedicalRecord : generates
  Pet ||--o{ Vaccination : receives
  MedicalRecord ||--o{ Prescription : includes
  InventoryItem ||--o{ InventoryBatch : stocks
  InventoryBatch ||--o{ InventoryTransaction : moves
  User ||--o{ ScanRecord : confirms
  User ||--o{ Notification : receives
```

## What was removed to match paper

- Roles `VETERINARIAN`, `STAFF`, `ADMIN` deleted. Only `PET_OWNER` + `OWNER_ADMIN`.
- Collections hidden from diagram: `auditLogs`, `users` management screens,
  `syncMetadata`, `deviceInfo`, `syncConflicts`, `counters`,
  `notificationPreferences`.
- Old `/staff`, `/vet`, `/admin` routes not shown - reserve only, gated to Owner/Admin.
