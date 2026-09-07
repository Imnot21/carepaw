# CarePaw Data Flow Diagram

**Project:** CarePaw - Smart Veterinary Patient Management System  
**Date:** 2026-09-07  
**Status:** ✅ DOCUMENTED

---

## Data Flow Diagram Overview

This document shows how data flows through the CarePaw system - from external actors through the application layers to the data stores and back.

---

## 1. Context Level Data Flow Diagram (Level 0)

```mermaid
flowchart TB
    %% External Entities
    PET_OWNER["🐾 Pet Owner\n(Mobile App)"]
    VETERINARIAN["🩺 Veterinarian\n(Mobile App)"]
    STAFF["🏥 Veterinary Staff\n(Mobile App)"]
    ADMIN["⚙️ Administrator\n(Web Dashboard)"]
    
    %% System Boundary
    subgraph CAREPAW["CarePaw System"]
        direction TB
        
        subgraph AUTH_LAYER["🔐 Authentication & Authorization"]
            AUTH["Auth Service\n(Firebase + Local)"]
            ROLE["Role Manager\n(PetOwner/Vet/Staff/Admin)"]
            TOKEN["Token Manager\n(JWT/Session)"]
        end
        
        subgraph FEATURE_LAYER["📦 Feature Modules"]
            PET_MGMT["🐕 Pet Management"]
            APPT_MGMT["📅 Appointment Management"]
            QUEUE_MGMT["📋 Queue Management"]
            MED_RECORDS["📝 Medical Records"]
            INV_MGMT["💊 Inventory Management"]
            SCAN_OCR["📷 Scanning/OCR"]
            NOTIFY["🔔 Notifications"]
            AUDIT["📊 Audit Logging"]
        end
        
        subgraph SYNC_LAYER["🔄 Data Synchronization"]
            SYNC_ENGINE["Sync Engine\n(Bi-directional)"]
            AUTH_SYNC["Auth Sync Service"]
            CONFLICT["Conflict Resolver\n(Last-Write-Wins)"]
        end
    end
    
    %% Data Stores
    subgraph DATA_STORES["💾 Data Stores"]
        LOCAL_DB["📱 Local Database\n(Drift/SQLite)\n- Users\n- Pets\n- Appointments\n- Medical Records\n- Inventory\n- Queue\n- Notifications\n- SyncMetadata"]
        
        FIRESTORE["☁️ Firestore\n- users (collection)\n- pets (collection)\n- appointments (collection)\n- medical_records (collection)\n- inventory (collection)\n- queue (collection)\n- notifications (collection)"]
        
        FIREBASE_AUTH["🔐 Firebase Auth\n- User Accounts\n- Custom Claims (Roles)"]
        
        FCM["📱 Firebase Cloud Messaging\n- Push Tokens\n- Message Queue"]
    end
    
    %% External Services
    OCR_SERVICE["🤖 OCR/AI Service\n(Google ML Kit / Cloud Vision)"]
    
    %% Data Flows - Pet Owner
    PET_OWNER -->|"Registration Data\nCredentials\nProfile Updates"| AUTH
    PET_OWNER -->|"Pet Data\nAppointment Requests\nRecord Views"| FEATURE_LAYER
    PET_OWNER -->|"FCM Token\nNotification Reads"| NOTIFY
    
    %% Data Flows - Veterinarian
    VETERINARIAN -->|"Credentials\nPatient Views\nRecord Creation\nTreatment Data"| FEATURE_LAYER
    
    %% Data Flows - Staff
    STAFF -->|"Credentials\nAppt Management\nQueue Operations\nInventory Ops\nScan Data"| FEATURE_LAYER
    
    %% Data Flows - Admin
    ADMIN -->|"Credentials\nSystem Config\nUser Management\nAnalytics"| FEATURE_LAYER
    
    %% Internal Flows
    AUTH -->|"User ID + Role\nSession Token"| FEATURE_LAYER
    AUTH -->|"Firebase UID"| FIREBASE_AUTH
    AUTH_SYNC -->|"Local Users\nw/o Firebase UID"| FIREBASE_AUTH
    FIREBASE_AUTH -->|"Firebase UID\nCustom Claims"| AUTH_SYNC
    AUTH_SYNC -->|"Updated Users"| LOCAL_DB
    
    FEATURE_LAYER -->|"CRUD Operations\n(Local First)"| LOCAL_DB
    LOCAL_DB -->|"Pending Changes\n(SyncMetadata)"| SYNC_ENGINE
    SYNC_ENGINE -->|"Upload Changes"| FIRESTORE
    FIRESTORE -->|"Remote Changes"| SYNC_ENGINE
    SYNC_ENGINE -->|"Apply Remote\nUpdate SyncMetadata"| LOCAL_DB
    CONFLICT -.->|"Resolve Conflicts"| SYNC_ENGINE
    
    SCAN_OCR -->|"Image Data"| OCR_SERVICE
    OCR_SERVICE -->|"Extracted Text\nConfidence Score"| SCAN_OCR
    
    NOTIFY -->|"Notification Payload"| FCM
    FCM -->|"Delivery Receipt"| NOTIFY
    
    FEATURE_LAYER -->|"Audit Events\n(User, Action, Entity,\nTimestamp, Changes)"| AUDIT
    AUDIT -->|"Audit Records"| LOCAL_DB
    AUDIT -->|"Audit Records"| FIRESTORE
    
    %% Styling
    classDef external fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:#000
    classDef auth fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef feature fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef sync fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000
    classDef store fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    classDef ext_svc fill:#f1f8e9,stroke:#558b2f,stroke-width:2px,color:#000
    
    class PET_OWNER,VETERINARIAN,STAFF,ADMIN external
    class AUTH,ROLE,TOKEN auth
    class PET_MGMT,APPT_MGMT,QUEUE_MGMT,MED_RECORDS,INV_MGMT,SCAN_OCR,NOTIFY,AUDIT feature
    class SYNC_ENGINE,AUTH_SYNC,CONFLICT sync
    class LOCAL_DB,FIRESTORE,FIREBASE_AUTH,FCM store
    class OCR_SERVICE ext_svc
```

---

## 2. Pet Management Data Flow (Level 1)

```mermaid
flowchart LR
    subgraph INPUT["Input"]
        PO_ADD["Pet Owner:\nAdd Pet Form"]
        PO_EDIT["Pet Owner:\nEdit Pet Form"]
        VET_VIEW["Veterinarian:\nView Patient"]
    end
    
    subgraph PROCESS["Pet Management Module"]
        VALIDATE["Validate Input\n- Required fields\n- Species enum\n- Weight range\n- DOB valid"]
        CHECK_OWNER["Verify Ownership\n(Authorization)"]
        PET_REPO["Pet Repository\n(Repository Pattern)"]
        CACHE["In-Memory Cache\n(Recent Pets)"]
    end
    
    subgraph STORAGE["Data Stores"]
        LOCAL_PETS["Local DB\npets table\n- id, owner_id, name\n  species, breed\n  weight_kg, dob\n  created_at, updated_at\n  is_deleted"]
        SYNC_PETS["SyncMetadata\nlast_pet_sync"]
        REMOTE_PETS["Firestore\npets collection\n/documents/{petId}"]
    end
    
    subgraph OUTPUT["Output"]
        PET_LIST["Pet List View"]
        PET_DETAIL["Pet Detail View"]
        PET_SUMMARY["Medical Summary\n(Aggregated)"]
    end
    
    PO_ADD --> VALIDATE
    PO_EDIT --> VALIDATE
    VET_VIEW --> CHECK_OWNER
    
    VALIDATE -->|Valid| PET_REPO
    VALIDATE -->|Invalid| PO_ADD
    VALIDATE -->|Invalid| PO_EDIT
    
    CHECK_OWNER -->|Authorized| PET_REPO
    CHECK_OWNER -->|Denied| VET_VIEW
    
    PET_REPO -->|Create/Update| LOCAL_PETS
    PET_REPO -->|Read| LOCAL_PETS
    PET_REPO -->|Read Cache| CACHE
    
    LOCAL_PETS -->|On Change| SYNC_PETS
    SYNC_PETS --> SYNC_ENGINE["Sync Engine"]
    SYNC_ENGINE -->|Upload| REMOTE_PETS
    REMOTE_PETS -->|Download| SYNC_ENGINE
    SYNC_ENGINE -->|Apply| LOCAL_PETS
    
    LOCAL_PETS --> PET_LIST
    LOCAL_PETS --> PET_DETAIL
    LOCAL_PETS -.->|Join with\nmedical_records| PET_SUMMARY
    
    classDef input fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef process fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef storage fill:#fce4ec,stroke:#c2185b,color:#000
    classDef output fill:#fff3e0,stroke:#ef6c00,color:#000
    
    class PO_ADD,PO_EDIT,VET_VIEW input
    class VALIDATE,CHECK_OWNER,PET_REPO,CACHE process
    class LOCAL_PETS,SYNC_PETS,REMOTE_PETS storage
    class PET_LIST,PET_DETAIL,PET_SUMMARY output
```

---

## 3. Appointment & Queue Data Flow (Level 1)

```mermaid
flowchart TB
    subgraph OWNER_ACTIONS["Pet Owner Actions"]
        REQ_APPT["Request Appointment\n- pet_id, service_type\n  preferred_date, time_slot"]
        VIEW_APPT["View My Appointments"]
        CHECK_QUEUE["Check Queue Position"]
    end
    
    subgraph STAFF_ACTIONS["Staff Actions"]
        MANAGE_APPT["Manage Appointments\n- Confirm/Reject\n- Reschedule"]
        CHECK_IN["Check In Patient\n- Add to Queue"]
        MANAGE_QUEUE["Manage Queue\n- Call Next\n- Update Status"]
    end
    
    subgraph VET_ACTIONS["Veterinarian Actions"]
        VIEW_PATIENTS["View Today's Patients"]
        START_CONSULT["Begin Consultation"]
        COMPLETE_CONSULT["Complete Consultation"]
    end
    
    subgraph APPT_MODULE["Appointment Module"]
        APPT_VALIDATE["Validate Request\n- Pet exists & owned\n- Slot available\n- Service valid"]
        APPT_REPO["Appointment Repository"]
        STATE_MACHINE["State Machine\nRequested→Confirmed→\nCheckedIn→InProgress→\nCompleted"]
        NOTIFY_APPT["Queue Notifications"]
    end
    
    subgraph QUEUE_MODULE["Queue Module"]
        QUEUE_REPO["Queue Repository"]
        POSITION_CALC["Calculate Position\n- FIFO by check-in\n- Priority (emergency)"]
        WAIT_ESTIMATE["Estimate Wait Time\n- Avg consult duration\n- Patients ahead"]
        QUEUE_NOTIFY["Queue Notifications\n- Position updates\n- Called alerts"]
    end
    
    subgraph STORES["Data Stores"]
        LOCAL_APPT["Local DB\nappointments table\n- id, pet_id, owner_id\n  vet_id, service_type\n  scheduled_at, status\n  created_at, updated_at"]
        LOCAL_QUEUE["Local DB\nqueue table\n- id, appointment_id\n  position, status\n  checked_in_at\n  called_at, room_entered_at\n  completed_at"]
        SYNC_META["SyncMetadata"]
        REMOTE_APPT["Firestore\nappointments collection"]
        REMOTE_QUEUE["Firestore\nqueue collection"]
    end
    
    REQ_APPT --> APPT_VALIDATE
    APPT_VALIDATE -->|Valid| APPT_REPO
    APPT_VALIDATE -->|Invalid| REQ_APPT
    
    APPT_REPO -->|Create: REQUESTED| LOCAL_APPT
    APPT_REPO -->|Read| LOCAL_APPT
    
    MANAGE_APPT --> APPT_REPO
    APPT_REPO -->|Update State| STATE_MACHINE
    STATE_MACHINE -->|Confirmed| LOCAL_APPT
    STATE_MACHINE -->|CheckedIn| QUEUE_REPO
    
    CHECK_IN --> QUEUE_REPO
    QUEUE_REPO -->|Add to Queue| LOCAL_QUEUE
    LOCAL_QUEUE --> POSITION_CALC
    POSITION_CALC -->|Position #| LOCAL_QUEUE
    LOCAL_QUEUE --> WAIT_ESTIMATE
    WAIT_ESTIMATE -->|Estimated mins| LOCAL_QUEUE
    
    MANAGE_QUEUE --> QUEUE_REPO
    QUEUE_REPO -->|Call Next| LOCAL_QUEUE
    QUEUE_REPO -->|Update Status| LOCAL_QUEUE
    
    VIEW_PATIENTS --> LOCAL_QUEUE
    LOCAL_QUEUE -->|Join appointments\n+ pets| VIEW_PATIENTS
    
    START_CONSULT --> QUEUE_REPO
    QUEUE_REPO -->|Status: IN_ROOM| LOCAL_QUEUE
    
    COMPLETE_CONSULT --> QUEUE_REPO
    QUEUE_REPO -->|Status: COMPLETED| LOCAL_QUEUE
    QUEUE_REPO -->|Trigger| NOTIFY_APPT
    NOTIFY_APPT --> QUEUE_NOTIFY
    QUEUE_NOTIFY -->|Next Patient\nPosition Update| CHECK_QUEUE
    
    LOCAL_APPT --> SYNC_META
    LOCAL_QUEUE --> SYNC_META
    SYNC_META --> SYNC_ENGINE["Sync Engine"]
    SYNC_ENGINE --> REMOTE_APPT
    SYNC_ENGINE --> REMOTE_QUEUE
    REMOTE_APPT --> SYNC_ENGINE
    REMOTE_QUEUE --> SYNC_ENGINE
    SYNC_ENGINE --> LOCAL_APPT
    SYNC_ENGINE --> LOCAL_QUEUE
    
    classDef owner fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef staff fill:#fff3e0,stroke:#ef6c00,color:#000
    classDef vet fill:#f3e5f5,stroke:#7b1fa2,color:#000
    classDef module fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef store fill:#fce4ec,stroke:#c2185b,color:#000
    
    class REQ_APPT,VIEW_APPT,CHECK_QUEUE owner
    class MANAGE_APPT,CHECK_IN,MANAGE_QUEUE staff
    class VIEW_PATIENTS,START_CONSULT,COMPLETE_CONSULT vet
    class APPT_VALIDATE,APPT_REPO,STATE_MACHINE,NOTIFY_APPT,QUEUE_REPO,POSITION_CALC,WAIT_ESTIMATE,QUEUE_NOTIFY module
    class LOCAL_APPT,LOCAL_QUEUE,SYNC_META,REMOTE_APPT,REMOTE_QUEUE store
```

---

## 4. Medical Records Data Flow (Level 1)

```mermaid
flowchart TB
    subgraph INPUTS["Data Inputs"]
        VET_ADD["Veterinarian:\nAdd Record Form\n- type, title, content\n  diagnosis, notes"]
        VET_VACC["Veterinarian:\nAdd Vaccination\n- vaccine_name, date\n  next_due, batch"]
        SCAN_MED["Scanner:\nOCR Extracted Med Data"]
        OWNER_VIEW["Pet Owner:\nView Records Request"]
    end
    
    subgraph MED_MODULE["Medical Records Module"]
        RECORD_VALIDATE["Validate Record\n- Required fields\n- Pet ownership\n- Type enum"]
        VACC_VALIDATE["Validate Vaccination\n- Required fields\n- Date logic\n- Next due calc"]
        RECORD_REPO["Medical Record\nRepository\n(Append-Only)"]
        VACC_REPO["Vaccination\nRepository"]
        ATTACHMENT["Attachment Handler\n(Images, PDFs)"]
        AGGREGATE["Record Aggregator\n- Timeline view\n- Filter by type/date"]
        REMINDER["Reminder Scheduler\n- Vaccination due\n- Follow-up"]
    end
    
    subgraph AUDIT_TRAIL["Audit Trail"]
        AUDIT_LOG["Audit Logger\n- User, Action, Entity\n- Before/After state\n- Timestamp"]
        IMMUTABLE["Immutable Store\n(Append-Only)"]
    end
    
    subgraph STORES["Data Stores"]
        LOCAL_RECORDS["Local DB\nmedical_records table\n- id, pet_id, vet_id\n  type, title, content\n  diagnosis, attachments\n  created_at (immutable)"]
        LOCAL_VACC["Local DB\nvaccinations table\n- id, pet_id, vet_id\n  vaccine_name, date\n  next_due, batch\n  created_at"]
        SYNC_RECORDS["SyncMetadata\nlast_records_sync"]
        REMOTE_RECORDS["Firestore\nmedical_records collection"]
        REMOTE_VACC["Firestore\nvaccinations collection"]
    end
    
    subgraph OUTPUTS["Data Outputs"]
        TIMELINE["Timeline View\n(Chronological)"]
        SUMMARY["Medical Summary\n(For Vet Dashboard)"]
        VACC_SCHEDULE["Vaccination Schedule\n(Upcoming Due)"]
        EXPORT["Export Records\n(PDF/CSV)"]
        REMINDER_NOTIF["Reminder Notifications"]
    end
    
    VET_ADD --> RECORD_VALIDATE
    RECORD_VALIDATE -->|Valid| RECORD_REPO
    RECORD_VALIDATE -->|Invalid| VET_ADD
    
    VET_VACC --> VACC_VALIDATE
    VACC_VALIDATE -->|Valid| VACC_REPO
    VACC_VALIDATE -->|Invalid| VET_VACC
    
    SCAN_MED -->|Creates Medicine| RECORD_REPO
    
    RECORD_REPO -->|Append Only| LOCAL_RECORDS
    RECORD_REPO -->|Audit Event| AUDIT_LOG
    
    VACC_REPO -->|Save| LOCAL_VACC
    VACC_REPO -->|Audit Event| AUDIT_LOG
    VACC_REPO -->|Schedule| REMINDER
    REMINDER -->|Due Date| REMINDER_NOTIF
    
    AUDIT_LOG --> IMMUTABLE
    
    OWNER_VIEW --> AGGREGATE
    AGGREGATE -->|Join Records +\nVaccinations| LOCAL_RECORDS
    AGGREGATE -->|Join Records +\nVaccinations| LOCAL_VACC
    LOCAL_RECORDS --> TIMELINE
    LOCAL_VACC --> TIMELINE
    LOCAL_RECORDS --> SUMMARY
    LOCAL_VACC --> VACC_SCHEDULE
    TIMELINE --> EXPORT
    
    LOCAL_RECORDS --> SYNC_RECORDS
    LOCAL_VACC --> SYNC_RECORDS
    SYNC_RECORDS --> SYNC_ENGINE["Sync Engine"]
    SYNC_ENGINE --> REMOTE_RECORDS
    SYNC_ENGINE --> REMOTE_VACC
    REMOTE_RECORDS --> SYNC_ENGINE
    REMOTE_VACC --> SYNC_ENGINE
    SYNC_ENGINE --> LOCAL_RECORDS
    SYNC_ENGINE --> LOCAL_VACC
    
    classDef input fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef module fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef audit fill:#f3e5f5,stroke:#7b1fa2,color:#000
    classDef store fill:#fce4ec,stroke:#c2185b,color:#000
    classDef output fill:#fff3e0,stroke:#ef6c00,color:#000
    
    class VET_ADD,VET_VACC,SCAN_MED,OWNER_VIEW input
    class RECORD_VALIDATE,VACC_VALIDATE,RECORD_REPO,VACC_REPO,ATTACHMENT,AGGREGATE,REMINDER module
    class AUDIT_LOG,IMMUTABLE audit
    class LOCAL_RECORDS,LOCAL_VACC,SYNC_RECORDS,REMOTE_RECORDS,REMOTE_VACC store
    class TIMELINE,SUMMARY,VACC_SCHEDULE,EXPORT,REMINDER_NOTIF output
```

---

## 5. Inventory & Scanning Data Flow (Level 1)

```mermaid
flowchart LR
    subgraph INPUTS["Inputs"]
        STAFF_MANUAL["Staff:\nManual Entry\n- Add Medicine\n- Stock In/Out\n- Adjustment"]
        SCAN_BOX["Scanner:\nMedicine Box\nImage Capture"]
        SCAN_RECEIPT["Scanner:\nReceipt\nImage Capture"]
    end
    
    subgraph SCAN_PIPELINE["Scanning Pipeline"]
        QUALITY_CHECK["Image Quality\nCheck\n- Blur detection\n- Lighting\n- Orientation"]
        OCR_PROCESS["OCR Processing\n- Text extraction\n- Field detection\n- Confidence scoring"]
        REVIEW_UI["Human Review UI\n- Auto-filled form\n- Confidence flags\n- Edit corrections"]
        DUPLICATE_CHECK["Duplicate Check\n- Medicine name\n- Batch + expiry"]
    end
    
    subgraph INV_MODULE["Inventory Module"]
        INV_VALIDATE["Validate Operation\n- Stock levels\n- Expiry dates\n- Batch tracking"]
        INV_REPO["Inventory\nRepository"]
        BATCH_TRACK["Batch Tracker\n- FIFO/LIFO\n- Expiry alerts"]
        TX_LOG["Transaction Log\n- STOCK_IN\n- STOCK_OUT\n- ADJUSTMENT\n- NEW_MEDICINE"]
        ALERTS["Alert Generator\n- Low stock\n- Expiring soon\n- Out of stock"]
    end
    
    subgraph STORES["Data Stores"]
        LOCAL_MEDS["Local DB\nmedicines table\n- id, name, description\n  min_stock_level\n  current_quantity\n  created_at"]
        LOCAL_BATCHES["Local DB\ninventory_batches table\n- id, medicine_id\n  quantity, expiry_date\n  batch_number\n  received_at"]
        LOCAL_TX["Local DB\ninventory_transactions table\n- id, medicine_id\n  batch_id, type\n  quantity, reason\n  reference_id\n  created_at"]
        SYNC_INV["SyncMetadata\nlast_inventory_sync"]
        REMOTE_INV["Firestore\ninventory collection\nbatches subcollection\ntransactions subcollection"]
    end
    
    subgraph OUTPUTS["Outputs"]
        INV_DASH["Inventory Dashboard\n- Current stock\n- Low stock alerts\n- Expiry timeline"]
        REPORTS["Reports\n- Low stock\n- Expiring soon\n- Transaction history\n- Usage analytics"]
        MED_FORM["Medicine Form\n(Pre-filled from scan)"]
    end
    
    SCAN_BOX --> QUALITY_CHECK
    SCAN_RECEIPT --> QUALITY_CHECK
    
    QUALITY_CHECK -->|Good| OCR_PROCESS
    QUALITY_CHECK -->|Poor| SCAN_BOX
    QUALITY_CHECK -->|Poor| SCAN_RECEIPT
    
    OCR_PROCESS -->|Extracted Data\n+ Confidence| REVIEW_UI
    REVIEW_UI -->|Confirmed| DUPLICATE_CHECK
    
    STAFF_MANUAL --> INV_VALIDATE
    DUPLICATE_CHECK --> INV_VALIDATE
    
    INV_VALIDATE -->|Valid| INV_REPO
    INV_VALIDATE -->|Invalid| STAFF_MANUAL
    INV_VALIDATE -->|Invalid| REVIEW_UI
    
    INV_REPO -->|Medicine CRUD| LOCAL_MEDS
    INV_REPO -->|Batch CRUD| LOCAL_BATCHES
    INV_REPO -->|Transaction| LOCAL_TX
    INV_REPO -->|Audit| TX_LOG
    
    LOCAL_BATCHES --> BATCH_TRACK
    BATCH_TRACK -->|Expiry Check| ALERTS
    LOCAL_MEDS -->|Stock Level Check| ALERTS
    LOCAL_TX -->|History| REPORTS
    
    ALERTS --> INV_DASH
    LOCAL_MEDS --> INV_DASH
    LOCAL_BATCHES --> INV_DASH
    
    REVIEW_UI -->|Duplicate Found\nMerge?| MED_FORM
    REVIEW_UI -->|New Medicine| MED_FORM
    
    LOCAL_MEDS --> SYNC_INV
    LOCAL_BATCHES --> SYNC_INV
    LOCAL_TX --> SYNC_INV
    SYNC_INV --> SYNC_ENGINE["Sync Engine"]
    SYNC_ENGINE --> REMOTE_INV
    REMOTE_INV --> SYNC_ENGINE
    SYNC_ENGINE --> LOCAL_MEDS
    SYNC_ENGINE --> LOCAL_BATCHES
    SYNC_ENGINE --> LOCAL_TX
    
    classDef input fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef scan fill:#fff8e1,stroke:#f57f17,color:#000
    classDef module fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef store fill:#fce4ec,stroke:#c2185b,color:#000
    classDef output fill:#fff3e0,stroke:#ef6c00,color:#000
    
    class STAFF_MANUAL,SCAN_BOX,SCAN_RECEIPT input
    class QUALITY_CHECK,OCR_PROCESS,REVIEW_UI,DUPLICATE_CHECK scan
    class INV_VALIDATE,INV_REPO,BATCH_TRACK,TX_LOG,ALERTS module
    class LOCAL_MEDS,LOCAL_BATCHES,LOCAL_TX,SYNC_INV,REMOTE_INV store
    class INV_DASH,REPORTS,MED_FORM output
```

---

## 6. Notification Data Flow (Level 1)

```mermaid
flowchart TB
    subgraph TRIGGERS["Event Triggers"]
        APPT_EVT["Appointment Events\n- Created\n- Confirmed\n- Rejected\n- Cancelled\n- Reminder"]
        QUEUE_EVT["Queue Events\n- Called\n- Position Update\n- Wait Time"]
        INV_EVT["Inventory Events\n- Low Stock\n- Expiring Soon\n- Out of Stock"]
        SYNC_EVT["Sync Events\n- Complete\n- Error"]
    end
    
    subgraph NOTIF_MODULE["Notification Module"]
        EVENT_ROUTER["Event Router\n- Map event →\n  notification type"]
        RECIPIENT_RESOLVER["Recipient Resolver\n- Pet owner (appt)\n- Vet (queue)\n- Staff (inventory)\n- Admin (system)"]
        CHANNEL_SELECTOR["Channel Selector\n- In-App\n- Local Push\n- Both"]
        TEMPLATE_ENGINE["Template Engine\n- Localized messages\n- Dynamic variables\n- Rich content"]
        NOTIF_REPO["Notification\nRepository"]
        DELIVERY["Delivery Service\n- In-App: Local DB\n- Push: FCM"]
        READ_TRACKER["Read Tracker\n- delivered_at\n- read_at"]
    end
    
    subgraph STORES["Data Stores"]
        LOCAL_NOTIF["Local DB\nnotifications table\n- id, user_id, type\n  title, body, data\n  channel, status\n  created_at, read_at"]
        FCM_STORE["FCM Service\n- Device tokens\n- Message queue\n- Delivery receipts"]
        SYNC_NOTIF["SyncMetadata\nlast_notif_sync"]
        REMOTE_NOTIF["Firestore\nnotifications collection"]
    end
    
    subgraph OUTPUTS["User Facing"]
        IN_APP["In-App Notification\n- Badge count\n- Notification center\n- Real-time updates"]
        PUSH_NOTIF["Push Notification\n- System tray\n- Lock screen\n- Background"]
        EMAIL["Email (Future)\n- Digest\n- Critical alerts"]
    end
    
    APPT_EVT --> EVENT_ROUTER
    QUEUE_EVT --> EVENT_ROUTER
    INV_EVT --> EVENT_ROUTER
    SYNC_EVT --> EVENT_ROUTER
    
    EVENT_ROUTER --> RECIPIENT_RESOLVER
    RECIPIENT_RESOLVER --> CHANNEL_SELECTOR
    CHANNEL_SELECTOR --> TEMPLATE_ENGINE
    TEMPLATE_ENGINE --> NOTIF_REPO
    
    NOTIF_REPO -->|Save: SENT| LOCAL_NOTIF
    NOTIF_REPO -->|In-App Channel| DELIVERY
    NOTIF_REPO -->|Push Channel| DELIVERY
    
    DELIVERY -->|In-App| IN_APP
    DELIVERY -->|Push| FCM_STORE
    FCM_STORE --> PUSH_NOTIF
    
    IN_APP -->|User Opens| READ_TRACKER
    PUSH_NOTIF -->|User Taps| READ_TRACKER
    READ_TRACKER -->|Update: READ\nread_at = now()| LOCAL_NOTIF
    
    LOCAL_NOTIF --> SYNC_NOTIF
    SYNC_NOTIF --> SYNC_ENGINE["Sync Engine"]
    SYNC_ENGINE --> REMOTE_NOTIF
    REMOTE_NOTIF --> SYNC_ENGINE
    SYNC_ENGINE --> LOCAL_NOTIF
    
    classDef trigger fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef module fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef store fill:#fce4ec,stroke:#c2185b,color:#000
    classDef output fill:#fff3e0,stroke:#ef6c00,color:#000
    
    class APPT_EVT,QUEUE_EVT,INV_EVT,SYNC_EVT trigger
    class EVENT_ROUTER,RECIPIENT_RESOLVER,CHANNEL_SELECTOR,TEMPLATE_ENGINE,NOTIF_REPO,DELIVERY,READ_TRACKER module
    class LOCAL_NOTIF,FCM_STORE,SYNC_NOTIF,REMOTE_NOTIF store
    class IN_APP,PUSH_NOTIF,EMAIL output
```

---

## 7. Data Synchronization Flow (Detailed)

```mermaid
flowchart TB
    subgraph LOCAL["Local Device (Offline-First)"]
        LOCAL_DB["Drift/SQLite\n- All Tables\n- SyncMetadata\n  (last_sync_ts,\n   entity_version)"]
        CHANGE_TRACKER["Change Tracker\n- Triggers on INSERT/UPDATE/DELETE\n- Writes to sync_queue table\n- entity, entity_id, operation\n  timestamp, payload"]
        SYNC_QUEUE["Sync Queue\n- Pending operations\n- Ordered by timestamp\n- Retry count"]
    end
    
    subgraph SYNC_PROCESS["Sync Process (Every 15 min, WiFi Only)"]
        SYNC_CONTROLLER["Sync Controller\n- Orchestrates flow\n- Handles scheduling"]
        AUTH_SYNC["Auth Sync\n- Local users → Firebase\n- Firebase UID → Local"]
        UPLOAD["Upload Manager\n- Read sync_queue\n- Batch operations\n- Conflict detection"]
        CONFLICT_RESOLVE["Conflict Resolver\n- Last-Write-Wins\n- Field-level merge\n- Manual for critical"]
        DOWNLOAD["Download Manager\n- Query Firestore\n  where updated_at > last_sync\n- Apply to local DB"]
        METADATA_UPDATE["Metadata Updater\n- Update SyncMetadata\n- last_sync_ts = now()\n- entity_versions"]
    end
    
    subgraph REMOTE["Cloud (Firestore)"]
        FIRESTORE_DB["Firestore\n- Collections per entity\n- Server timestamps\n- Security rules"]
        AUTH_FIREBASE["Firebase Auth\n- User accounts\n- Custom claims"]
    end
    
    LOCAL_DB -->|Triggers| CHANGE_TRACKER
    CHANGE_TRACKER -->|Enqueue| SYNC_QUEUE
    
    SYNC_CONTROLLER -->|Schedule| AUTH_SYNC
    AUTH_SYNC -->|Local users\nw/o Firebase UID| AUTH_FIREBASE
    AUTH_FIREBASE -->|Firebase UID\nCustom Claims| AUTH_SYNC
    AUTH_SYNC -->|Update Local| LOCAL_DB
    
    SYNC_CONTROLLER -->|Trigger| UPLOAD
    UPLOAD -->|Read Queue| SYNC_QUEUE
    UPLOAD -->|Batch Write| FIRESTORE_DB
    FIRESTORE_DB -->|Conflict?| CONFLICT_RESOLVE
    CONFLICT_RESOLVE -->|Resolved| FIRESTORE_DB
    CONFLICT_RESOLVE -->|Mark Synced| SYNC_QUEUE
    
    SYNC_CONTROLLER -->|Trigger| DOWNLOAD
    DOWNLOAD -->|Query Changes| FIRESTORE_DB
    FIRESTORE_DB -->|Remote Changes| DOWNLOAD
    DOWNLOAD -->|Apply Local| LOCAL_DB
    
    DOWNLOAD --> METADATA_UPDATE
    UPLOAD --> METADATA_UPDATE
    METADATA_UPDATE -->|Update Timestamp| LOCAL_DB
    
    classDef local fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef process fill:#e8f5e9,stroke:#2e7d32,color:#000
    classDef remote fill:#fce4ec,stroke:#c2185b,color:#000
    
    class LOCAL_DB,CHANGE_TRACKER,SYNC_QUEUE local
    class SYNC_CONTROLLER,AUTH_SYNC,UPLOAD,CONFLICT_RESOLVE,DOWNLOAD,METADATA_UPDATE process
    class FIRESTORE_DB,AUTH_FIREBASE remote
```

---

## 8. Data Entities & Relationships

```mermaid
erDiagram
    USERS ||--o{ PETS : owns
    USERS ||--o{ APPOINTMENTS : "owner (PetOwner)"
    USERS ||--o{ APPOINTMENTS : "vet (Veterinarian)"
    USERS ||--o{ MEDICAL_RECORDS : "vet (author)"
    USERS ||--o{ VACCINATIONS : "vet (author)"
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ INVENTORY_TRANSACTIONS : "staff (performed_by)"
    
    PETS ||--o{ APPOINTMENTS : has
    PETS ||--o{ MEDICAL_RECORDS : has
    PETS ||--o{ VACCINATIONS : has
    PETS ||--o{ QUEUE : "via appointment"
    
    APPOINTMENTS ||--|| QUEUE : generates
    APPOINTMENTS ||--o{ MEDICAL_RECORDS : "results in"
    
    MEDICINES ||--o{ INVENTORY_BATCHES : has
    MEDICINES ||--o{ INVENTORY_TRANSACTIONS : tracks
    INVENTORY_BATCHES ||--o{ INVENTORY_TRANSACTIONS : references
    
    SYNC_METADATA }|--|| USERS : tracks
    SYNC_METADATA }|--|| PETS : tracks
    SYNC_METADATA }|--|| APPOINTMENTS : tracks
    SYNC_METADATA }|--|| MEDICAL_RECORDS : tracks
    SYNC_METADATA }|--|| VACCINATIONS : tracks
    SYNC_METADATA }|--|| MEDICINES : tracks
    SYNC_METADATA }|--|| INVENTORY_BATCHES : tracks
    SYNC_METADATA }|--|| INVENTORY_TRANSACTIONS : tracks
    SYNC_METADATA }|--|| NOTIFICATIONS : tracks
    SYNC_METADATA }|--|| QUEUE : tracks
```

---

## 9. Data Flow Summary Table

| Data Entity | Source | Local Store | Remote Store | Sync Direction | Conflict Strategy |
|-------------|--------|-------------|--------------|----------------|-------------------|
| Users | Auth (Firebase + Local) | users table | users collection | Bi-directional | Firebase UID wins |
| Pets | Pet Owner / Vet | pets table | pets collection | Bi-directional | Last-Write-Wins |
| Appointments | Pet Owner / Staff | appointments table | appointments collection | Bi-directional | State machine validates |
| Queue | Staff / Vet | queue table | queue collection | Bi-directional | Position recalculated |
| Medical Records | Vet (Append-Only) | medical_records table | medical_records collection | Bi-directional | Immutable - no conflicts |
| Vaccinations | Vet (Append-Only) | vaccinations table | vaccinations collection | Bi-directional | Immutable - no conflicts |
| Medicines | Staff / Scanner | medicines table | inventory collection | Bi-directional | Last-Write-Wins |
| Inventory Batches | Staff / Scanner | inventory_batches table | inventory/batches subcollection | Bi-directional | Last-Write-Wins |
| Inventory Transactions | Staff / System | inventory_transactions table | inventory/transactions subcollection | Append-Only | Immutable - no conflicts |
| Notifications | System Events | notifications table | notifications collection | Bi-directional | Last-Write-Wins |

---

## 10. Security & Privacy Data Flow

```mermaid
flowchart LR
    subgraph CLIENT["Client Device"]
        ENCRYPT["Encrypt Sensitive Data\n- PII (names, emails)\n- Medical content\n- AES-256 local"]
        AUTH_STORAGE["Secure Storage\n- Tokens (Flutter Secure Storage)\n- Biometric unlock"]
        INPUT_VAL["Input Validation\n- Client-side\n- Sanitization"]
    end
    
    subgraph TRANSIT["In Transit"]
        TLS["TLS 1.3\n- All network calls\n- Certificate pinning"]
        FIREBASE_RULES["Firestore Rules\n- Role-based access\n- Owner-only reads\n- Staff write own"]
    end
    
    subgraph SERVER["Cloud"]
        FIREBASE_AUTH["Firebase Auth\n- Email/Password\n- Custom claims (roles)\n- MFA support"]
        AUDIT_LOG["Audit Log\n- All sensitive ops\n- Immutable\n- Retention policy"]
        BACKUP["Automated Backup\n- Point-in-time recovery\n- Encrypted at rest"]
    end
    
    CLIENT -->|Encrypted Payload| TLS
    TLS --> FIREBASE_RULES
    FIREBASE_RULES --> FIREBASE_AUTH
    FIREBASE_RULES --> AUDIT_LOG
    AUDIT_LOG --> BACKUP
    
    AUTH_STORAGE -->|Tokens| TLS
    INPUT_VAL -->|Sanitized| TLS
    
    classDef client fill:#e3f2fd,stroke:#1565c0,color:#000
    classDef transit fill:#fff3e0,stroke:#ef6c00,color:#000
    classDef server fill:#fce4ec,stroke:#c2185b,color:#000
    
    class ENCRYPT,AUTH_STORAGE,INPUT_VAL client
    class TLS,FIREBASE_RULES transit
    class FIREBASE_AUTH,AUDIT_LOG,BACKUP server
```

---

*Generated as part of CarePaw thesis project - Data Flow Diagram Documentation*