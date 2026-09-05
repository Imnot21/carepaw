# CarePaw System Workflows

This document describes the key workflows of the CarePaw Smart Veterinary Patient Management System, suitable for thesis documentation.

## 1. Pet Owner Journey

### 1.1 Appointment Request Workflow

```mermaid
sequenceDiagram
    participant PO as Pet Owner
    participant UI as Flutter App
    participant API as Repository Layer
    participant DB as Local DB (Drift)
    participant NOTIF as Notification System
    
    PO->>UI: Select Pet
    UI->>API: getPets(ownerId)
    API->>DB: SELECT FROM pets WHERE owner_id = ?
    DB-->>API: Pet list
    API-->>UI: Pet list
    UI-->>PO: Display pet selector
    
    PO->>UI: Select Service & Date/Time
    UI->>API: checkAvailability(vetId, scheduledAt)
    API->>DB: SELECT FROM appointments WHERE veterinarian_id = ? AND scheduled_at = ?
    DB-->>API: Availability result
    API-->>UI: Available slots
    UI-->>PO: Show confirmed time
    
    PO->>UI: Submit Request (reason, notes)
    UI->>API: createAppointment(Appointment)
    API->>DB: INSERT INTO appointments (status=REQUESTED)
    DB-->>API: appointmentId
    API->>NOTIF: notifyStaff(New appointment request)
    API-->>UI: Success
    UI-->>PO: Request submitted (status: REQUESTED)
```

### 1.2 Queue Monitoring Workflow

```mermaid
sequenceDiagram
    participant PO as Pet Owner
    participant UI as Flutter App
    participant API as Repository/DAO
    participant DB as Local DB (Drift)
    participant WS as Stream Subscription
    
    PO->>UI: Navigate to Queue Screen
    UI->>API: watchCurrentQueue()
    API->>DB: SELECT FROM queue_entries JOIN appointments JOIN pets WHERE status IN (WAITING, CALLED, IN_ROOM)
    DB-->>API: Real-time stream
    API-->>UI: Stream<List<QueueEntryWithDetails>>
    
    Note over WS: DB-authoritative state changes
    WS->>API: queue position update
    API->>DB: UPDATE queue_entries SET position = ?
    DB-->>WS: emit new stream event
    WS-->>UI: Updated queue
    UI-->>PO: Display "You are #3, 2 ahead"
    
    Note over WS: Staff calls next patient
    WS->>API: staff calls patient
    API->>DB: UPDATE queue_entries SET status=CALLED WHERE position=1
    DB-->>WS: emit event
    WS-->>UI: Queue updates
    UI-->>PO: Display "Now serving #1"
```

---

## 2. Veterinary Staff Journey

### 2.1 Appointment Management Workflow

```mermaid
flowchart TD
    A[Staff Login] --> B[View Appointment Requests]
    B --> C{Decision}
    C -->|Valid| D[CONFIRM]
    C -->|Invalid| E[REJECT with reason]
    D --> F[Appointment: CONFIRMED]
    E --> G[Appointment: CANCELLED]
    F --> H[Notify Pet Owner]
    G --> H
    H --> I[Appointment appears in schedule]
    
    I --> J[Pet Owner checks in]
    J --> K[Queue Entry: WAITING]
    K --> L[Staff calls patient]
    L --> M[Queue Entry: CALLED]
    M --> N[Patient enters room]
    N --> O[Queue Entry: IN_ROOM]
    O --> P[Appointment: IN_PROGRESS]
    P --> Q[Veterinarian consultation]
    Q --> R[Appointment: COMPLETED]
    R --> S[Queue Entry: COMPLETED]
```

### 2.2 Inventory Scanning Workflow

```mermaid
sequenceDiagram
    participant S as Staff
    participant UI as Flutter App
    participant OCR as OCR Engine
    participant API as Repository Layer
    participant DB as Local DB (Drift)
    participant TXN as Transaction Logger
    
    S->>UI: Scan Medicine Box
    UI->>OCR: captureImage()
    OCR-->>UI: rawOcrText + extractedData + confidenceScore
    UI->>API: createScanRecord(scanType, imagePath, rawOcrText, extractedData, confidenceScore)
    API->>DB: INSERT INTO scan_records (status=PENDING)
    DB-->>API: scanRecordId
    API-->>UI: Scan preview
    
    Note over S,UI: HUMAN VERIFICATION GATE
    UI-->>S: Display extracted data for review
    S->>UI: Correct/confirm data
    
    alt Confirms Scan
        S->>UI: Confirm
        UI->>API: confirmScan(scanRecordId, corrections, confirmedBy)
        API->>DB: UPDATE scan_records SET status=CONFIRMED, confirmedBy=?, confirmedAt=NOW(), corrections=?
        API->>DB: INSERT INTO inventory_batches (inventoryId, batchNumber, quantity, expiresAt)
        API->>DB: INSERT INTO inventory_transactions (type=IN, quantityChange=?, quantityBefore=0, quantityAfter=?, performedBy=?)
        API->>DB: UPDATE inventory_items SET currentStock = currentStock + ?
        API->>TXN: logInventoryChange()
        API-->>UI: Success
        UI-->>S: Inventory updated
    else Rejects Scan
        S->>UI: Reject
        UI->>API: rejectScan(scanRecordId, confirmedBy)
        API->>DB: UPDATE scan_records SET status=REJECTED, confirmedBy=?
        API-->>UI: Rejected
        UI-->>S: Scan discarded
    end
```

---

## 3. Veterinarian Journey

### 3.1 Medical Record Creation Workflow

```mermaid
flowchart TD
    A[Vet Login] --> B[View Assigned Appointments]
    B --> C[Select Appointment IN_PROGRESS]
    C --> D[Open Pet Record]
    D --> E[Review Medical History]
    E --> F[Perform Consultation]
    F --> G[Create Medical Record]
    G --> H{Record Type?}
    H -->|VISIT| I[Record diagnosis, treatment]
    H -->|VACCINATION| J[Record vaccine name, batch, next_due]
    H -->|LAB_RESULT| K[Attach results]
    H -->|PRESCRIPTION| L[Create Prescription]
    
    I --> M[INSERT INTO medical_records]
    J --> M
    K --> M
    L --> N[INSERT INTO prescriptions]
    N --> M
    
    M --> O[Notify Pet Owner]
    O --> P[Record Complete]
    
    Note over D,M: APPEND-ONLY INTEGRITY
    Note over D,M: No destructive updates
    Note over E: Authorization check: vet can only access assigned pets
```

### 3.2 Prescription Management

```mermaid
sequenceDiagram
    participant V as Veterinarian
    participant UI as Flutter App
    participant API as Repository
    participant DB as Local DB
    
    V->>UI: Create Prescription
    UI->>API: createPrescription(medicalRecordId, petId, medicationName, dosage, frequency, durationDays, quantity, refillsRemaining)
    API->>DB: INSERT INTO prescriptions (status=ACTIVE, prescribedAt=NOW())
    DB-->>API: prescriptionId
    API->>DB: SELECT FROM pets WHERE id = ? (authorization check)
    API-->>UI: Success
    UI-->>V: Prescription created
    
    Note over V,DB: Refill logic
    V->>UI: Request Refill
    UI->>API: decrementRefill(prescriptionId)
    API->>DB: UPDATE prescriptions SET refillsRemaining = refillsRemaining - 1 WHERE refillsRemaining > 0
    DB-->>API: rows affected
    API-->>UI: Success/Failure
```

---

## 4. Administrator Journey

### 4.1 User Management Workflow

```mermaid
flowchart TD
    A[Admin Login] --> B[Audit Dashboard]
    B --> C[Review Audit Logs]
    C --> D{Action Required?}
    D -->|Suspicious Activity| E[Deactivate User]
    D -->|Routine| F[Export Report]
    D -->|User Request| G[Role Change]
    
    E --> H[UPDATE users SET isActive=false]
    G --> I[UPDATE users SET role=?]
    F --> J[Generate CSV/PDF]
    
    H --> K[Log admin action to audit_logs]
    I --> K
    J --> K
    
    Note over A,K: All admin actions logged
    Note over A,K: Authorization enforced server-side
```

### 4.2 System Configuration Workflow

```mermaid
sequenceDiagram
    participant A as Admin
    participant UI as Flutter App
    participant API as Repository
    participant DB as Local DB
    participant CONFIG as Config Store
    
    A->>UI: Navigate to Settings
    UI->>API: getClinicConfig()
    API->>DB: SELECT FROM clinic_config WHERE id = 1
    DB-->>API: Config object
    API-->>UI: Display settings
    UI-->>A: Show current config
    
    A->>UI: Update settings (e.g., appointment duration)
    UI->>API: updateClinicConfig(changes)
    API->>DB: UPDATE clinic_config SET appointmentDurationMinutes = ? WHERE id = 1
    API->>CONFIG: notifyListeners()
    API-->>UI: Success
    UI-->>A: Settings saved
    
    Note over A,DB: Changes affect future appointments only
```

---

## 5. Cross-Cutting Workflows

### 5.1 Notification Delivery Workflow

```mermaid
flowchart LR
    A[Event Trigger] --> B{Notification Type?}
    B -->|APPOINTMENT_REMINDER| C[Check user preferences]
    B -->|QUEUE_UPDATE| C
    B -->|PRESCRIPTION_READY| C
    B -->|INVENTORY_LOW| C
    B -->|SYSTEM| C
    
    C --> D{User enabled?}
    D -->|Yes| E[Create notification record]
    D -->|No| F[Skip]
    
    E --> G{Channel enabled?}
    G -->|In-App| H[Store in notifications table]
    G -->|Push| I[Send FCM push]
    G -->|Email| J[Send email via service]
    
    H --> K[Mark as UNREAD]
    I --> K
    J --> K
    
    Note over E,K: Never expose sensitive medical info in notifications
```

### 5.2 Data Sync Workflow

```mermaid
sequenceDiagram
    participant UI as Flutter App
    participant API as Repository
    participant DB as Local DB (Drift)
    participant CLOUD as Cloud Sync Service
    participant META as SyncMetadata
    
    Note over UI,META: Offline-first architecture
    UI->>API: Perform local mutation
    API->>DB: INSERT/UPDATE/DELETE
    API->>META: INSERT INTO sync_metadata (operation, payload, createdAt, deviceId)
    API-->>UI: Success (offline)
    
    Note over CLOUD,META: When connectivity available
    CLOUD->>META: GET unsynced records WHERE syncedAt IS NULL
    META-->>CLOUD: Pending operations
    CLOUD->>API: Push to server
    API->>META: UPDATE sync_metadata SET syncedAt=NOW() WHERE id = ?
    API->>DB: Mark as synced
    
    Note over CLOUD,META: Conflict resolution
    CLOUD->>META: GET version conflicts
    META-->>CLOUD: Conflicting records
    CLOUD->>API: Resolve via last-write-wins or merge
```

### 5.3 Audit Logging Workflow

```mermaid
sequenceDiagram
    participant U as User
    participant API as Repository/Service
    participant AUDIT as AuditLogger
    participant DB as Local DB
    
    U->>API: Sensitive Operation (e.g., create medical record)
    API->>AUDIT: logAction(userId, action, entityType, entityId, oldValues, newValues)
    AUDIT->>DB: INSERT INTO audit_logs (userId, action, entityType, entityId, oldValues, newValues, ipAddress, userAgent, createdAt)
    AUDIT-->>API: Logged
    API->>DB: Perform actual operation
    API-->>U: Result
    
    Note over U,DB: All sensitive operations logged
    Note over U,DB: Audit log is append-only (no updates/deletes)
```

---

## State Machine Summary

| Entity | States | Initial | Terminal States |
|--------|--------|---------|-----------------|
| Appointment | REQUESTED, CONFIRMED, CHECKED_IN, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW | REQUESTED | COMPLETED, CANCELLED, NO_SHOW |
| QueueEntry | WAITING, CALLED, IN_ROOM, COMPLETED, SKIPPED | WAITING | COMPLETED, SKIPPED |
| ScanRecord | PENDING, CONFIRMED, REJECTED | PENDING | CONFIRMED, REJECTED |
| Prescription | ACTIVE, COMPLETED, CANCELLED, EXPIRED | ACTIVE | COMPLETED, CANCELLED, EXPIRED |
| InventoryTransaction | IN, OUT, ADJUSTMENT | (type at creation) | (immutable) |
| User | ACTIVE, INACTIVE (isActive flag) | ACTIVE | INACTIVE (soft delete) |
| Pet | ACTIVE, INACTIVE (isActive flag) | ACTIVE | INACTIVE (soft delete) |
| Notification | UNREAD, READ | UNREAD | READ |

---

## Key Workflow Principles

1. **Database-Authoritative State**: All state transitions happen in DB, not in UI
2. **Human Verification**: OCR scans never auto-update inventory
3. **Traceability**: Every inventory change logged as transaction
4. **Append-Only**: Medical records never destructively updated
5. **Soft Deletion**: Users/Pets use isActive flag, not hard delete
6. **Authorization Enforced**: Server-side checks, not UI-only
7. **Audit Trail**: All sensitive operations logged
8. **Offline-First**: Local mutations tracked in sync_metadata
9. **Notification Safety**: No sensitive medical info in notifications
10. **FIFO Inventory**: Batches consumed by expiration date

---

*These workflows are implemented in the feature-layer architecture under `lib/features/*/presentation`, `lib/features/*/application`, and `lib/features/*/data`.*