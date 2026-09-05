# CarePaw System Flowcharts

**Project:** CarePaw - Smart Veterinary Patient Management System
**Date:** 2026-08-26
**Status:** ✅ DOCUMENTED

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Authentication Flow](#2-authentication-flow)
3. [Pet Owner Journey](#3-pet-owner-journey)
4. [Veterinarian Journey](#4-veterinarian-journey)
5. [Veterinary Staff Journey](#5-veterinary-staff-journey)
6. [Appointment State Machine](#6-appointment-state-machine)
7. [Queue Management Flow](#7-queue-management-flow)
8. [Inventory Management Flow](#8-inventory-management-flow)
9. [Medical Records Flow](#9-medical-records-flow)
10. [OCR/Scanning Workflow](#10-ocrscanning-workflow)
11. [Notification Flow](#11-notification-flow)
12. [Data Synchronization Flow](#12-data-synchronization-flow)

---

## 1. System Overview

```mermaid
flowchart TB
    subgraph Users["👤 User Roles"]
        PO["🐾 Pet Owner"]
        VET["🩺 Veterinarian"]
        STAFF["🏥 Veterinary Staff"]
        ADMIN["⚙️ Administrator"]
    end

    subgraph CoreSystem["🏥 CarePaw Core System"]
        AUTH["🔐 Authentication Module"]
        APPT["📅 Appointment Module"]
        QUEUE["📋 Queue Module"]
        PET["🐕 Pet Management"]
        MED["📝 Medical Records"]
        INV["💊 Inventory Module"]
        SCAN["📷 Scanning/OCR"]
        NOTIFY["🔔 Notifications"]
        AUDIT["📊 Audit Logging"]
    end

    subgraph DataLayer["💾 Data Layer"]
        LOCALDB["🗄️ Local Database (Drift/SQLite)"]
        FIREBASE["☁️ Firebase Auth/Firestore"]
        SYNC["🔄 Background Sync"]
    end

    subgraph External["🌐 External Services"]
        FCM["📱 Firebase Cloud Messaging"]
        OCR_SVC["🤖 OCR/AI Service"]
    end

    PO --> AUTH
    VET --> AUTH
    STAFF --> AUTH
    ADMIN --> AUTH

    AUTH --> APPT
    AUTH --> PET
    AUTH --> MED

    APPT --> QUEUE
    QUEUE --> NOTIFY

    PET --> MED
    MED --> AUDIT

    INV --> SCAN
    SCAN --> OCR_SVC

    LOCALDB --> SYNC
    SYNC --> FIREBASE

    NOTIFY --> FCM
```

---

## 2. Authentication Flow

```mermaid
flowchart TD
    START([🚀 App Launch]) --> INIT["Initialize Firebase"]
    INIT --> CHECK_AUTH{"🔐 Check\nExisting Session"}

    CHECK_AUTH -->|No Session| SPLASH["Show Splash Screen"]
    SPLASH --> LOGIN_PAGE["📱 Login Page"]
    SPLASH --> REGISTER_PAGE["📝 Registration Page"]

    LOGIN_PAGE --> INPUT_EMAIL["Enter Email"]
    INPUT_EMAIL --> INPUT_PASS["Enter Password"]
    INPUT_PASS --> SUBMIT_LOGIN["Submit Login"]

    SUBMIT_LOGIN --> VALIDATE{"✅ Validate\nCredentials"}
    VALIDATE -->|Invalid| SHOW_ERR["❌ Show Error\nMessage"]
    SHOW_ERR --> INPUT_EMAIL

    VALIDATE -->|Valid| SAVE_LOCAL["💾 Save Session\nLocally"]
    SAVE_LOCAL --> SYNC_FIREBASE["☁️ Sync to Firebase Auth"]
    SYNC_FIREBASE --> UPDATE_UID["Update firebaseUid\nin Local DB"]
    UPDATE_UID --> CHECK_ROLE{"Check User Role"}

    REGISTER_PAGE --> REG_NAME["Enter Full Name"]
    REG_NAME --> REG_EMAIL["Enter Email"]
    REG_EMAIL --> REG_PASS["Enter Password"]
    REG_PASS --> REG_CONFIRM["Confirm Password"]
    REG_CONFIRM --> SELECT_ROLE["Select Role"]

    SELECT_ROLE --> REG_VALIDATE{"✅ Validate\nRegistration"}
    REG_VALIDATE -->|Invalid| REG_ERR["❌ Show Error"]
    REG_ERR --> REG_NAME

    REG_VALIDATE -->|Valid| CREATE_LOCAL["💾 Create Local Account"]
    CREATE_LOCAL --> CREATE_FIREBASE["☁️ Create Firebase Auth\nUser"]
    CREATE_FIREBASE --> SAVE_FIRESTORE["📄 Save to Firestore\nusers Collection"]
    SAVE_FIRESTORE --> UPDATE_LOCAL["Update Local DB\nwith Firebase UID"]
    UPDATE_LOCAL --> CHECK_ROLE

    CHECK_ROLE -->|PET_OWNER| PO_HOME["🏠 Pet Owner Dashboard"]
    CHECK_ROLE -->|VETERINARIAN| VET_HOME["🏠 Veterinarian Dashboard"]
    CHECK_ROLE -->|STAFF| STAFF_HOME["🏠 Staff Dashboard"]
    CHECK_ROLE -->|ADMIN| ADMIN_HOME["🏠 Admin Dashboard"]

    CHECK_AUTH -->|Has Session| CHECK_ROLE

    PO_HOME --> SYNC_START["🔄 Start Background Sync"]
    VET_HOME --> SYNC_START
    STAFF_HOME --> SYNC_START
    ADMIN_HOME --> SYNC_START

    SYNC_START --> SYNC_INTERVAL["📡 Sync Every 15 min\n(WiFi Only)"]

    style START fill:#4CAF50,color:#fff
    style SHOW_ERR fill:#f44336,color:#fff
    style REG_ERR fill:#f44336,color:#fff
    style SAVE_LOCAL fill:#2196F3,color:#fff
    style CREATE_LOCAL fill:#2196F3,color:#fff
    style SYNC_FIREBASE fill:#FF9800,color:#fff
    style CREATE_FIREBASE fill:#FF9800,color:#fff
```

---

## 3. Pet Owner Journey

```mermaid
flowchart TD
    START([🏠 Pet Owner Dashboard]) --> SELECT_ACTION{"Select Action"}

    SELECT_ACTION -->|Add Pet| ADD_PET["➕ Add New Pet"]
    SELECT_ACTION -->|View Pets| VIEW_PETS["📋 My Pets List"]
    SELECT_ACTION -->|Book Appt| BOOK_APPT["📅 Book Appointment"]
    SELECT_ACTION -->|View Appt| VIEW_APPT["📅 My Appointments"]
    SELECT_ACTION -->|Check Queue| CHECK_QUEUE["📋 Check Queue Status"]
    SELECT_ACTION -->|View Records| VIEW_RECORDS["📝 View Pet Records"]
    SELECT_ACTION -->|Notifications| VIEW_NOTIFY["🔔 Notifications"]

    ADD_PET --> PET_NAME["Enter Pet Name"]
    PET_NAME --> PET_SPECIES["Select Species\nDog/Cat/Other"]
    PET_SPECIES --> PET_BREED["Enter Breed"]
    PET_BREED --> PET_WEIGHT["Enter Weight (kg)"]
    PET_WEIGHT --> PET_DOB["Enter Date of Birth"]
    PET_DOB --> SAVE_PET["💾 Save Pet"]
    SAVE_PET --> VIEW_PETS

    BOOK_APPT --> SELECT_PET["🐕 Select Pet"]
    SELECT_PET --> SELECT_SERVICE["💊 Select Service\nConsultation/Vaccination/etc"]
    SELECT_SERVICE --> SELECT_DATE["📅 Select Date"]
    SELECT_DATE --> SELECT_TIME["⏰ Select Time Slot"]
    SELECT_TIME --> SUBMIT_APPT["📤 Submit Appointment\nRequest"]
    SUBMIT_APPT --> APPT_CONFIRMED["✅ Appointment\nRequested"]
    APPT_CONFIRMED --> WAIT_CONFIRM["⏳ Waiting for\nStaff Confirmation"]

    VIEW_PETS --> PET_DETAIL["📄 Pet Detail View"]
    PET_DETAIL --> EDIT_PET["✏️ Edit Pet Info"]
    PET_DETAIL --> VIEW_MED["📝 View Medical\nHistory"]

    CHECK_QUEUE --> QUEUE_STATUS["📊 Queue Status\nCurrent #, Position\nEstimated Wait"]
    QUEUE_STATUS --> WAIT_NOTIF["🔔 Will Receive\nNotification When\nYour Turn"]

    VIEW_NOTIFY --> NOTIF_LIST["📋 Notification List"]
    NOTIF_LIST --> MARK_READ["✅ Mark as Read"]

    style START fill:#4CAF50,color:#fff
    style APPT_CONFIRMED fill:#4CAF50,color:#fff
    style WAIT_CONFIRM fill:#FF9800,color:#fff
    style SUBMIT_APPT fill:#2196F3,color:#fff
    style SAVE_PET fill:#2196F3,color:#fff
```

---

## 4. Veterinarian Journey

```mermaid
flowchart TD
    START([🏠 Vet Dashboard]) --> SELECT_ACTION{"Select Action"}

    SELECT_ACTION -->|View Patients| VIEW_PATIENTS["📋 Today's Patients"]
    SELECT_ACTION -->|View Appointments| VIEW_APPT["📅 My Appointments"]
    SELECT_ACTION -->|Open Record| OPEN_RECORD["📝 Open Pet Record"]
    SELECT_ACTION -->|Add Record| ADD_RECORD["➕ Add Medical Record"]
    SELECT_ACTION -->|Record Treatment| RECORD_TREATMENT["💊 Record Treatment"]
    SELECT_ACTION -->|Notifications| VIEW_NOTIFY["🔔 Notifications"]

    VIEW_PATIENTS --> PATIENT_LIST["📋 Patient List\nwith Queue Status"]
    PATIENT_LIST --> PATIENT_DETAIL["📄 Patient Detail"]
    PATIENT_DETAIL --> VIEW_HISTORY["📜 View Medical\nHistory"]

    VIEW_HISTORY --> VIEW_VACC["💉 Vaccination History"]
    VIEW_HISTORY --> VIEW_TREAT["💊 Treatment History"]
    VIEW_HISTORY --> VIEW_NOTES["📝 Clinical Notes"]

    OPEN_RECORD --> PET_INFO["🐕 Pet Information\nSpecies/Breed/Weight"]
    PET_INFO --> PET_MEDICAL["📋 Medical Summary"]
    PET_MEDICAL --> ADD_RECORD

    ADD_RECORD --> RECORD_TYPE["Select Record Type\nConsultation/Treatment\nVaccination/Note"]
    RECORD_TYPE --> RECORD_CONTENT["Enter Content\nClinical Findings"]
    RECORD_CONTENT --> RECORD_DIAGNOSIS["Enter Diagnosis"]
    RECORD_DIAGNOSIS --> RECORD_NOTES["Add Clinical Notes"]
    RECORD_NOTES --> SAVE_RECORD["💾 Save Record\n(Append Only)"]
    SAVE_RECORD --> AUDIT_LOG["📊 Audit Log Entry"]

    RECORD_TREATMENT --> TREAT_PET["🐕 Select Patient"]
    TREAT_PET --> TREAT_DESC["Describe Treatment"]
    TREAT_DESC --> TREAT_MEDS["💊 Prescribe Medicines\n(Optional)"]
    TREAT_MEDS --> SAVE_TREATMENT["💾 Save Treatment"]
    SAVE_TREATMENT --> ADD_RECORD

    VIEW_NOTIFY --> NOTIF_LIST["📋 Notifications"]
    NOTIF_LIST --> MARK_READ["✅ Mark as Read"]

    style START fill:#4CAF50,color:#fff
    style SAVE_RECORD fill:#2196F3,color:#fff
    style SAVE_TREATMENT fill:#2196F3,color:#fff
    style AUDIT_LOG fill:#FF9800,color:#fff
```

---

## 5. Veterinary Staff Journey

```mermaid
flowchart TD
    START([🏠 Staff Dashboard]) --> SELECT_ACTION{"Select Action"}

    SELECT_ACTION -->|Manage Appointments| MANAGE_APPT["📅 Manage Appointments"]
    SELECT_ACTION -->|Manage Queue| MANAGE_QUEUE["📋 Manage Queue"]
    SELECT_ACTION -->|Check In| CHECK_IN["✅ Check In Patient"]
    SELECT_ACTION -->|Manage Inventory| MANAGE_INV["💊 Inventory Management"]
    SELECT_ACTION -->|Process Scan| PROCESS_SCAN["📷 Process Scan"]
    SELECT_ACTION -->|Notifications| SEND_NOTIFY["🔔 Send Notifications"]

    MANAGE_APPT --> APPT_LIST["📋 Appointment List"]
    APPT_LIST --> CONFIRM_APPT["✅ Confirm Appointment"]
    APPT_LIST --> REJECT_APPT["❌ Reject Appointment"]
    APPT_LIST --> RESCHEDULE["🔄 Reschedule"]
    CONFIRM_APPT --> NOTIFY_OWNER["📱 Notify Pet Owner"]
    REJECT_APPT --> NOTIFY_OWNER
    RESCHEDULE --> NOTIFY_OWNER

    MANAGE_QUEUE --> QUEUE_VIEW["📊 Queue Dashboard\nCurrent #, Waiting Count"]
    QUEUE_VIEW --> CALL_NEXT["📞 Call Next Patient"]
    QUEUE_VIEW --> UPDATE_STATUS["📝 Update Queue Status"]
    QUEUE_VIEW --> COMPLETE_PATIENT["✅ Complete Patient"]

    CHECK_IN --> SEARCH_PET["🔍 Search Pet/Owner"]
    SEARCH_PET --> VERIFY_INFO["✅ Verify Information"]
    VERIFY_INFO --> ADD_TO_QUEUE["📋 Add to Queue"]
    ADD_TO_QUEUE --> SET_POSITION["🔢 Set Queue Position"]
    SET_POSITION --> NOTIFY_VET["📱 Notify Veterinarian"]

    MANAGE_INV --> INV_VIEW["📊 Inventory Dashboard"]
    INV_VIEW --> ADD_MEDICINE["➕ Add New Medicine"]
    INV_VIEW --> STOCK_IN["📥 Stock In"]
    INV_VIEW --> STOCK_OUT["📤 Stock Out"]
    INV_VIEW --> ADJUST["📝 Adjust Stock"]
    INV_VIEW --> CHECK_EXPIRY["⏰ Check Expiry Dates"]

    ADD_MEDICINE --> MED_NAME["Enter Medicine Name"]
    MED_NAME --> MED_QTY["Enter Quantity"]
    MED_QTY --> MED_EXPIRY["Enter Expiry Date"]
    MED_EXPIRY --> MED_BATCH["Enter Batch Number"]
    MED_BATCH --> SAVE_MED["💾 Save Medicine"]

    STOCK_IN --> SELECT_MED["💊 Select Medicine"]
    SELECT_MED --> IN_QTY["Enter Quantity\nIncoming"]
    IN_QTY --> IN_BATCH["Enter Batch #\n(Optional)"]
    IN_BATCH --> IN_REASON["Enter Reason"]
    IN_REASON --> SAVE_STOCK_IN["💾 Save Stock In\n+ Transaction Log"]
    SAVE_STOCK_IN --> UPDATE_STOCK["📊 Update Current\nQuantity"]

    PROCESS_SCAN --> SCAN_TYPE["📷 Select Scan Type\nMedicine Box/Receipt"]
    SCAN_TYPE --> CAPTURE_IMAGE["📸 Capture Image"]
    CAPTURE_IMAGE --> OCR_EXTRACT["🤖 OCR Extraction"]
    OCR_EXTRACT --> REVIEW_DATA["📝 Review Extracted\nData"]
    REVIEW_DATA --> CORRECT_ERRORS["✏️ Correct Any\nErrors"]
    CORRECT_ERRORS --> CONFIRM_DATA["✅ Confirm Data"]
    CONFIRM_DATA --> UPDATE_INV["📦 Update Inventory"]

    SEND_NOTIFY --> NOTIFY_TYPE["Select Notification\nType"]
    NOTIFY_TYPE --> NOTIFY_CONTENT["Enter Content"]
    NOTIFY_CONTENT --> SELECT_RECIPIENTS["👥 Select Recipients"]
    SELECT_RECIPIENTS --> SEND["📤 Send Notification"]

    style START fill:#4CAF50,color:#fff
    style SAVE_STOCK_IN fill:#2196F3,color:#fff
    style CONFIRM_DATA fill:#4CAF50,color:#fff
    style OCR_EXTRACT fill:#FF9800,color:#fff
```

---

## 6. Appointment State Machine

```mermaid
stateDiagram-v2
    [*] --> Requested: Pet Owner Submits

    Requested --> Confirmed: Staff Confirms
    Requested --> Rejected: Staff Rejects
    Requested --> Cancelled: Owner Cancels

    Confirmed --> CheckedIn: Patient Arrives
    Confirmed --> Cancelled: Owner Cancels
    Confirmed --> NoShow: Missed Appointment

    CheckedIn --> InProgress: Vet Begins
    CheckedIn --> Cancelled: Patient Leaves

    InProgress --> Completed: Visit Ends
    InProgress --> Cancelled: Issue Arises

    Completed --> [*]
    Rejected --> [*]
    Cancelled --> [*]
    NoShow --> [*]

    note right of Requested
        Initial state when
        appointment is created
    end note

    note right of Confirmed
        Staff has confirmed
        the appointment
    end note

    note right of CheckedIn
        Patient has arrived
        and is in queue
    end note

    note right of InProgress
        Veterinarian is
        seeing the patient
    end note

    note right of Completed
        Visit completed
        Record created
    end note
```

---

## 7. Queue Management Flow

```mermaid
flowchart TD
    START([📋 Queue System]) --> PATIENT_ARRIVES["🏥 Patient Arrives"]

    PATIENT_ARRIVES --> STAFF_CHECK["Staff Verifies\nAppointment"]
    STAFF_CHECK --> CONFIRM_APT{"Appointment\nConfirmed?"}

    CONFIRM_APT -->|No| CREATE_WALKIN["Create Walk-In\nAppointment"]
    CREATE_WALKIN --> ADD_QUEUE

    CONFIRM_APT -->|Yes| CHECK_IN["✅ Check In Patient"]
    CHECK_IN --> ADD_QUEUE["📋 Add to Queue"]

    ADD_QUEUE --> ASSIGN_POS["🔢 Assign Queue\nPosition"]
    ASSIGN_POS --> SET_STATUS["📝 Set Status:\nWAITING"]
    SET_STATUS --> NOTIFY_VET_QUEUE["📱 Notify Vet:\nNew Patient"]

    NOTIFY_VET_QUEUE --> WAIT_CALL["⏳ Waiting to\nBe Called"]

    WAIT_CALL --> VET_READY["🩺 Vet Ready\nfor Next Patient"]
    VET_READY --> CALL_NEXT["📞 Call Next\nin Queue"]
    CALL_NEXT --> UPDATE_STATUS_CALLED["📝 Status: CALLED"]
    UPDATE_STATUS_CALLED --> PATIENT_MOVES["🚶 Patient Moves\nto Exam Room"]
    PATIENT_MOVES --> UPDATE_STATUS_ROOM["📝 Status: IN_ROOM"]
    UPDATE_STATUS_ROOM --> ROOM_ENTERED["Record Room\nEntry Time"]

    ROOM_ENTERED --> VET_CONSULTS["🩺 Veterinary\nConsultation"]
    VET_CONSULTS --> CONSULTATION_COMPLETE["✅ Consultation\nComplete"]
    CONSULTATION_COMPLETE --> UPDATE_STATUS_COMPLETE["📝 Status: COMPLETED"]
    UPDATE_STATUS_COMPLETE --> RECORD_COMPLETION["Record Completion\nTime"]
    RECORD_COMPLETION --> NOTIFY_NEXT["📱 Notify Next\nPatient"]
    NOTIFY_NEXT --> CALC_WAIT["📊 Update Wait\nTimes"]

    CALC_WAIT --> CHECK_MORE{"More Patients\nin Queue?"}
    CHECK_MORE -->|Yes| WAIT_CALL
    CHECK_MORE -->|No| QUEUE_EMPTY["Queue Empty"]

    QUEUE_EMPTY --> END_SESSION["End Queue Session"]

    style START fill:#4CAF50,color:#fff
    style CHECK_IN fill:#2196F3,color:#fff
    style CALL_NEXT fill:#FF9800,color:#fff
    style CONSULTATION_COMPLETE fill:#4CAF50,color:#fff
    style QUEUE_EMPTY fill:#9E9E9E,color:#fff
```

---

## 8. Inventory Management Flow

```mermaid
flowchart TD
    START([💊 Inventory System]) --> SELECT_OP{"Select Operation"}

    SELECT_OP -->|Add Medicine| ADD_MED["➕ Add New Medicine"]
    SELECT_OP -->|Stock In| STOCK_IN["📥 Stock In"]
    SELECT_OP -->|Stock Out| STOCK_OUT["📤 Stock Out"]
    SELECT_OP -->|Adjust| ADJUST["📝 Adjust Stock"]
    SELECT_OP -->|View Reports| REPORTS["📊 Inventory Reports"]

    ADD_MED --> MED_FORM["Enter Medicine Details\nName, Description\nMin Stock Level"]
    MED_FORM --> VALIDATE_MED{"✅ Validate\nMedicine"}
    VALIDATE_MED -->|Invalid| MED_ERR["❌ Show Error"]
    MED_ERR --> MED_FORM
    VALIDATE_MED -->|Valid| SAVE_MED_DB["💾 Save Medicine\nin Database"]
    SAVE_MED_DB --> CREATE_TX["📝 Create Transaction\nRecord: NEW_MEDICINE"]

    STOCK_IN --> SELECT_MED_IN["💊 Select Medicine"]
    SELECT_MED_IN --> IN_FORM["Enter Details\nQuantity, Batch #\nExpiry Date, Reason"]
    IN_FORM --> VALIDATE_IN{"✅ Validate\nStock In"}
    VALIDATE_IN -->|Invalid| IN_ERR["❌ Show Error"]
    IN_ERR --> IN_FORM
    VALIDATE_IN -->|Valid| SAVE_BATCH["💾 Save Inventory\nBatch"]
    SAVE_BATCH --> CREATE_TX_IN["📝 Create Transaction:\nSTOCK_IN"]
    CREATE_TX_IN --> UPDATE_QTY_IN["📊 Update Medicine\nCurrent Quantity"]
    UPDATE_QTY_IN --> CHECK_MIN{"Below Minimum\nStock Level?"}
    CHECK_MIN -->|Yes| LOW_STOCK_ALERT["⚠️ Low Stock Alert"]
    CHECK_MIN -->|No| DONE_IN["✅ Stock In Complete"]

    STOCK_OUT --> SELECT_MED_OUT["💊 Select Medicine"]
    SELECT_MED_OUT --> OUT_FORM["Enter Details\nQuantity, Reason\nPatient/Appointment"]
    OUT_FORM --> VALIDATE_OUT{"✅ Validate\nStock Out"}
    VALIDATE_OUT -->|Insufficient Stock| STOCK_ERR["❌ Insufficient\nStock Error"]
    STOCK_ERR --> OUT_FORM
    VALIDATE_OUT -->|Valid| SAVE_OUT_TX["📝 Create Transaction:\nSTOCK_OUT"]
    SAVE_OUT_TX --> UPDATE_QTY_OUT["📊 Update Medicine\nCurrent Quantity"]
    UPDATE_QTY_OUT --> CHECK_REMAINING{"Stock Below\nMinimum?"}
    CHECK_REMAINING -->|Yes| LOW_STOCK_ALERT2["⚠️ Low Stock Alert"]
    CHECK_REMAINING -->|No| DONE_OUT["✅ Stock Out Complete"]

    ADJUST --> SELECT_ADJ_MED["💊 Select Medicine"]
    SELECT_ADJ_MED --> ADJ_FORM["Enter Adjustment\nNew Quantity, Reason"]
    ADJ_FORM --> VALIDATE_ADJ{"✅ Validate\nAdjustment"}
    VALIDATE_ADJ -->|Invalid| ADJ_ERR["❌ Show Error"]
    ADJ_ERR --> ADJ_FORM
    VALIDATE_ADJ -->|Valid| SAVE_ADJ_TX["📝 Create Transaction:\nADJUSTMENT"]
    SAVE_ADJ_TX --> UPDATE_ADJ_QTY["📊 Update Medicine\nCurrent Quantity"]
    UPDATE_ADJ_QTY --> DONE_ADJ["✅ Adjustment Complete"]

    REPORTS --> REPORT_TYPE{"Select Report"}
    REPORT_TYPE --> LOW_STOCK_RPT["📉 Low Stock\nReport"]
    REPORT_TYPE --> EXPIRY_RPT["⏰ Expiring\nSoon Report"]
    REPORT_TYPE --> TX_HISTORY["📜 Transaction\nHistory"]
    REPORT_TYPE --> USAGE_RPT["📊 Usage\nAnalytics"]

    style START fill:#4CAF50,color:#fff
    style SAVE_MED_DB fill:#2196F3,color:#fff
    style CREATE_TX_IN fill:#FF9800,color:#fff
    style LOW_STOCK_ALERT fill:#f44336,color:#fff
    style LOW_STOCK_ALERT2 fill:#f44336,color:#fff
    style STOCK_ERR fill:#f44336,color:#fff
```

---

## 9. Medical Records Flow

```mermaid
flowchart TD
    START([📝 Medical Records]) --> SELECT_ACTION{"Select Action"}

    SELECT_ACTION -->|View Records| VIEW_RECORDS["📋 View Pet Records"]
    SELECT_ACTION -->|Add Record| ADD_RECORD["➕ Add Record"]
    SELECT_ACTION -->|Add Vaccination| ADD_VACC["💉 Add Vaccination"]
    SELECT_ACTION -->|View History| VIEW_HISTORY["📜 View History"]

    VIEW_RECORDS --> SELECT_PET["🐕 Select Pet"]
    SELECT_PET --> PET_RECORDS["📋 Pet's Medical\nRecords List"]
    PET_RECORDS --> FILTER_TYPE["Filter by Type\nConsultation/Treatment\nVaccination/Note"]
    FILTER_TYPE --> VIEW_DETAIL["📄 View Record\nDetail"]

    ADD_RECORD --> RECORD_FORM["📝 Record Form"]
    RECORD_FORM --> R_SELECT_PET["🐕 Select Pet"]
    R_SELECT_PET --> R_TYPE["Select Record Type"]
    R_TYPE --> R_TITLE["Enter Title"]
    R_TITLE --> R_CONTENT["Enter Content\nClinical Findings\nDiagnosis, Notes"]
    R_CONTENT --> R_ATTACHMENTS["📎 Add Attachments\n(Optional)"]
    R_ATTACHMENTS --> VALIDATE_R{"✅ Validate\nRecord"}
    VALIDATE_R -->|Invalid| R_ERR["❌ Show Error"]
    R_ERR --> RECORD_FORM
    VALIDATE_R -->|Valid| SAVE_RECORD_DB["💾 Save Record\n(Append Only)"]
    SAVE_RECORD_DB --> AUDIT_R["📊 Audit Log\nRecord Created"]
    AUDIT_R --> NOTIFY_OWNER_R["📱 Notify Pet Owner\nNew Record Available"]

    ADD_VACC --> VACC_FORM["💉 Vaccination Form"]
    VACC_FORM --> V_SELECT_PET["🐕 Select Pet"]
    V_SELECT_PET --> V_NAME["Enter Vaccine Name"]
    V_NAME --> V_DATE["Select Administration\nDate"]
    V_DATE --> V_NEXT_DUE["Set Next Due Date"]
    V_NEXT_DUE --> V_BATCH["Enter Batch Number\n(Optional)"]
    V_BATCH --> V_NOTES["Add Notes\n(Optional)"]
    V_NOTES --> VALIDATE_V{"✅ Validate\nVaccination"}
    VALIDATE_V -->|Invalid| V_ERR["❌ Show Error"]
    V_ERR --> VACC_FORM
    VALIDATE_V -->|Valid| SAVE_VACC_DB["💾 Save Vaccination\nRecord"]
    SAVE_VACC_DB --> SCHEDULE_REMINDER["⏰ Schedule\nReminder for\nNext Due Date"]
    SCHEDULE_REMINDER --> AUDIT_V["📊 Audit Log\nVaccination Recorded"]

    VIEW_HISTORY --> H_SELECT_PET["🐕 Select Pet"]
    H_SELECT_PET --> H_TIMELINE["📜 Timeline View\nof All Records"]
    H_TIMELINE --> H_FILTER["Filter by Date Range\nRecord Type"]
    H_FILTER --> H_EXPORT["📥 Export Records\n(Optional)"]

    style START fill:#4CAF50,color:#fff
    style SAVE_RECORD_DB fill:#2196F3,color:#fff
    style SAVE_VACC_DB fill:#2196F3,color:#fff
    style AUDIT_R fill:#FF9800,color:#fff
    style AUDIT_V fill:#FF9800,color:#fff
```

---

## 10. OCR/Scanning Workflow

```mermaid
flowchart TD
    START([📷 Scanning System]) --> SELECT_SCAN{"Select Scan Type"}

    SELECT_SCAN -->|Medicine Box| MED_SCAN["💊 Medicine Box\nScan"]
    SELECT_SCAN -->|Receipt| RECEIPT_SCAN["🧾 Receipt\nScan"]

    MED_SCAN --> CAPTURE_MED["📸 Capture Image\nof Medicine Box"]
    CAPTURE_MED --> IMAGE_CHECK{"Image Quality\nCheck"}

    IMAGE_CHECK -->|Poor Quality| RETAKE_MED["⚠️ Poor Image\nPlease Retake"]
    RETAKE_MED --> CAPTURE_MED

    IMAGE_CHECK -->|Good| OCR_MED["🤖 OCR Processing\nExtract Medicine\nName, Dosage, Expiry"]

    OCR_MED --> EXTRACT_DATA["📋 Extracted Data:\n- Medicine Name\n- Dosage\n- Expiry Date\n- Batch Number\n- Manufacturer"]

    EXTRACT_DATA --> CONFIDENCE_CHECK{"Confidence\nScore?"}

    CONFIDENCE_CHECK -->|< 70%| LOW_CONF["⚠️ Low Confidence\nManual Review Required"]
    LOW_CONF --> MANUAL_ENTRY["✏️ Manual Entry\nor Correction"]

    CONFIDENCE_CHECK -->|≥ 70%| AUTO_FILL["📝 Auto-Fill Form\nwith Extracted Data"]

    AUTO_FILL --> REVIEW_MED["📝 Review Extracted\nData"]
    MANUAL_ENTRY --> REVIEW_MED

    REVIEW_MED --> CORRECTION{"Any Corrections\nNeeded?"}
    CORRECTION -->|Yes| EDIT_FIELD["✏️ Edit Fields"]
    EDIT_FIELD --> REVIEW_MED
    CORRECTION -->|No| CONFIRM_MED["✅ Confirm Data"]

    CONFIRM_MED --> CHECK_DUPLICATE{"🔍 Check for\nDuplicate Medicine"}
    CHECK_DUPLICATE -->|Duplicate Found| DUP_ALERT["⚠️ Duplicate Found\nExisting Stock: X"]
    DUP_ALERT --> MERGE_DECISION{"Merge or\nCreate New?"}
    MERGE_DECISION -->|Merge| UPDATE_EXISTING["📦 Update Existing\nMedicine Stock"]
    MERGE_DECISION -->|Create New| CREATE_NEW_MED["➕ Create New\nMedicine Entry"]

    CHECK_DUPLICATE -->|No Duplicate| CREATE_NEW_MED

    UPDATE_EXISTING --> SAVE_SCAN_MED["💾 Save Scan Result\nStatus: CONFIRMED"]
    CREATE_NEW_MED --> SAVE_SCAN_MED

    RECEIPT_SCAN --> CAPTURE_RECEIPT["📸 Capture Receipt\nImage"]
    CAPTURE_RECEIPT --> RCPT_CHECK{"Image Quality\nCheck"}

    RCPT_CHECK -->|Poor Quality| RETAKE_RCPT["⚠️ Poor Image\nPlease Retake"]
    RETAKE_RCPT --> CAPTURE_RECEIPT

    RCPT_CHECK -->|Good| OCR_RECEIPT["🤖 OCR Processing\nExtract Receipt\nData"]

    OCR_RECEIPT --> EXTRACT_RCPT["📋 Extracted Data:\n- Items\n- Quantities\n- Prices\n- Date"]

    EXTRACT_RCPT --> REVIEW_RCPT["📝 Review Extracted\nData"]
    REVIEW_RCPT --> CONFIRM_RCPT["✅ Confirm Receipt\nData"]

    CONFIRM_RCPT --> PROCESS_ITEMS["📦 Process Each\nMedicine Item"]
    PROCESS_ITEMS --> MATCH_INV{"Match with\nExisting Inventory?"}
    MATCH_INV -->|Match Found| ADD_STOCK["📥 Add to Existing\nStock"]
    MATCH_INV -->|No Match| CREATE_MED_ITEM["➕ Create New\nMedicine Entry"]

    ADD_STOCK --> SAVE_SCAN_RCPT["💾 Save Scan Result\nStatus: PROCESSED"]
    CREATE_MED_ITEM --> SAVE_SCAN_RCPT

    SAVE_SCAN_MED --> AUDIT_SCAN["📊 Audit Log\nScan Processed"]
    SAVE_SCAN_RCPT --> AUDIT_SCAN

    style START fill:#4CAF50,color:#fff
    style RETAKE_MED fill:#f44336,color:#fff
    style RETAKE_RCPT fill:#f44336,color:#fff
    style LOW_CONF fill:#FF9800,color:#fff
    style CONFIRM_MED fill:#4CAF50,color:#fff
    style CONFIRM_RCPT fill:#4CAF50,color:#fff
```

---

## 11. Notification Flow

```mermaid
flowchart TD
    START([🔔 Notification System]) --> EVENT_TRIGGER{"Event Trigger"}

    EVENT_TRIGGER -->|Appointment| APPT_EVENT["📅 Appointment Event"]
    EVENT_TRIGGER -->|Queue| QUEUE_EVENT["📋 Queue Event"]
    EVENT_TRIGGER -->|Inventory| INV_EVENT["💊 Inventory Event"]
    EVENT_TRIGGER -->|System| SYS_EVENT["⚙️ System Event"]

    APPT_EVENT --> APPT_TYPE{"Appointment\nEvent Type"}
    APPT_TYPE -->|Created| APPT_CREATED["📱 New Appointment\nRequest"]
    APPT_TYPE -->|Confirmed| APPT_CONFIRMED["📱 Appointment\nConfirmed"]
    APPT_TYPE -->|Rejected| APPT_REJECTED["📱 Appointment\nRejected"]
    APPT_TYPE -->|Cancelled| APPT_CANCELLED["📱 Appointment\nCancelled"]
    APPT_TYPE -->|Reminder| APPT_REMINDER["📱 Appointment\nReminder"]

    QUEUE_EVENT --> QUEUE_TYPE{"Queue\nEvent Type"}
    QUEUE_TYPE -->|Called| QUEUE_CALLED["📱 Your Turn!\nPlease Proceed"]
    QUEUE_TYPE -->|Position Update| QUEUE_POSITION["📱 Queue Position\nUpdated"]
    QUEUE_TYPE -->|Wait Time| QUEUE_WAIT["📱 Estimated\nWait Time"]

    INV_EVENT --> INV_TYPE{"Inventory\nEvent Type"}
    INV_TYPE -->|Low Stock| LOW_STOCK["⚠️ Low Stock\nAlert"]
    INV_TYPE -->|Expiring Soon| EXPIRY["⏰ Medicine\nExpiring Soon"]
    INV_TYPE -->|Out of Stock| OUT_STOCK["🚨 Out of Stock\nAlert"]

    SYS_EVENT --> SYS_TYPE{"System\nEvent Type"}
    SYS_TYPE -->|Sync Complete| SYNC_DONE["🔄 Sync Complete"]
    SYS_TYPE -->|Sync Error| SYNC_ERR["⚠️ Sync Error\nPlease Check"]

    APPT_CREATED --> DETERMINE_RECIPIENTS["👥 Determine\nRecipients"]
    APPT_CONFIRMED --> DETERMINE_RECIPIENTS
    APPT_REJECTED --> DETERMINE_RECIPIENTS
    APPT_CANCELLED --> DETERMINE_RECIPIENTS
    APPT_REMINDER --> DETERMINE_RECIPIENTS

    QUEUE_CALLED --> DETERMINE_RECIPIENTS
    QUEUE_POSITION --> DETERMINE_RECIPIENTS
    QUEUE_WAIT --> DETERMINE_RECIPIENTS

    LOW_STOCK --> DETERMINE_RECIPIENTS
    EXPIRY --> DETERMINE_RECIPIENTS
    OUT_STOCK --> DETERMINE_RECIPIENTS

    SYNC_DONE --> DETERMINE_RECIPIENTS
    SYNC_ERR --> DETERMINE_RECIPIENTS

    DETERMINE_RECIPIENTS --> SELECT_CHANNEL{"Select\nChannel"}

    SELECT_CHANNEL -->|In-App| IN_APP["📱 In-App\nNotification"]
    SELECT_CHANNEL -->|Local Push| LOCAL_PUSH["🔔 Local Push\nNotification"]
    SELECT_CHANNEL -->|Both| BOTH["📱🔔 Both\nChannels"]

    IN_APP --> SAVE_NOTIFICATION["💾 Save to\nnotifications Table"]
    LOCAL_PUSH --> SEND_LOCAL["📤 Send via\nLocalNotificationService"]
    BOTH --> SAVE_NOTIFICATION
    BOTH --> SEND_LOCAL

    SAVE_NOTIFICATION --> MARK_SENT["📝 Status: SENT"]
    SEND_LOCAL --> MARK_SENT

    MARK_SENT --> USER_RECEIVES["👤 User Receives\nNotification"]
    USER_RECEIVES --> USER_READS{"User Reads\nNotification?"}
    USER_READS -->|Yes| MARK_READ["📝 Status: READ\nRecord readAt"]
    USER_READS -->|No| REMAIN_UNREAD["⏳ Remains\nUnread"]

    MARK_READ --> NOTIF_COMPLETE["✅ Notification\nComplete"]
    REMAIN_UNREAD --> REMIND_LATER["⏰ May Remind\nLater"]

    style START fill:#4CAF50,color:#fff
    style APPT_CONFIRMED fill:#4CAF50,color:#fff
    style APPT_REJECTED fill:#f44336,color:#fff
    style LOW_STOCK fill:#FF9800,color:#fff
    style EXPIRY fill:#FF9800,color:#fff
    style OUT_STOCK fill:#f44336,color:#fff
    style SYNC_ERR fill:#f44336,color:#fff
```

---

## 12. Data Synchronization Flow

```mermaid
flowchart TD
    START([🔄 Sync System]) --> INIT_SYNC["Initialize Sync\nController"]

    INIT_SYNC --> AUTH_SYNC["🔐 Auth Sync Service\nStarted"]

    AUTH_SYNC --> CHECK_LOCAL_USERS["📋 Check Local\nUsers Table"]

    CHECK_LOCAL_USERS --> LOCAL_USERS{"Local Users\nWithout Firebase UID?"}

    LOCAL_USERS -->|Yes| FOR_EACH_USER["🔄 For Each\nUnsynced User"]

    FOR_EACH_USER --> CREATE_FIREBASE["☁️ Create Firebase\nAuth Account"]
    CREATE_FIREBASE --> FIREBASE_RESULT{"Firebase\nCreation Result"}

    FIREBASE_RESULT -->|Success| SAVE_FIRESTORE["📄 Save User Data\nto Firestore\nusers Collection"]
    FIREBASE_RESULT -->|Email Exists| CHECK_FIRESTORE["🔍 Query Firestore\nfor Existing User\nby Email"]
    FIREBASE_RESULT -->|Error| LOG_ERROR["⚠️ Log Error\nSkip User"]

    CHECK_FIRESTORE --> FIRESTORE_FOUND{"User Found\nin Firestore?"}
    FIRESTORE_FOUND -->|Yes| UPDATE_LOCAL_UID["📝 Update Local DB\nwith Firebase UID"]
    FIRESTORE_FOUND -->|No| SKIP_USER["⏭️ Skip User"]

    SAVE_FIRESTORE --> UPDATE_LOCAL_UID
    LOG_ERROR --> NEXT_USER["⏭️ Next Unsynced\nUser"]
    SKIP_USER --> NEXT_USER

    UPDATE_LOCAL_UID --> NEXT_USER

    NEXT_USER --> MORE_USERS{"More Unsynced\nUsers?"}
    MORE_USERS -->|Yes| FOR_EACH_USER
    MORE_USERS -->|No| AUTH_SYNC_COMPLETE["✅ Auth Sync\nComplete"]

    LOCAL_USERS -->|No| AUTH_SYNC_COMPLETE

    AUTH_SYNC_COMPLETE --> DATA_SYNC["📊 Data Sync\n(Bi-directional)"]

    DATA_SYNC --> CHECK_METADATA["🔍 Check\nSyncMetadata\nTable"]
    CHECK_METADATA --> LAST_SYNC["Get Last Sync\nTimestamp"]

    LAST_SYNC --> PENDING_CHANGES{"Pending Local\nChanges?"}

    PENDING_CHANGES -->|Yes| UPLOAD_CHANGES["📤 Upload Changes\nto Firestore"]
    UPLOAD_CHANGES --> CONFLICT_CHECK{"Conflict\nDetected?"}

    CONFLICT_CHECK -->|No Conflict| APPLY_REMOTE["📥 Apply Remote\nChanges Locally"]
    CONFLICT_CHECK -->|Conflict| RESOLVE_CONFLICT["⚖️ Resolve Conflict\n(Last Write Wins)"]
    RESOLVE_CONFLICT --> APPLY_REMOTE

    PENDING_CHANGES -->|No| APPLY_REMOTE

    APPLY_REMOTE --> UPDATE_SYNC_META["📝 Update\nSyncMetadata\nTimestamp"]
    UPDATE_SYNC_META --> SYNC_COMPLETE["✅ Sync Cycle\nComplete"]

    SYNC_COMPLETE --> WAIT_INTERVAL["⏳ Wait 15 Minutes\n(WiFi Only)"]
    WAIT_INTERVAL --> DATA_SYNC

    style START fill:#4CAF50,color:#fff
    style AUTH_SYNC_COMPLETE fill:#4CAF50,color:#fff
    style SYNC_COMPLETE fill:#4CAF50,color:#fff
    style LOG_ERROR fill:#f44336,color:#fff
    style CONFLICT_CHECK fill:#FF9800,color:#fff
```

---

## Appendix: Legend

| Symbol | Meaning |
|--------|---------|
| 🟢 Green | Start/End/Success |
| 🔵 Blue | Primary Action |
| 🟠 Orange | Warning/Decision |
| 🔴 Red | Error/Failure |
| ⬜ Gray | Idle/Complete |

---

*Generated as part of CarePaw thesis project - System Flowcharts Documentation*
