# CarePaw — User Guide

Welcome to CarePaw! This guide walks you through the main workflows for pet
owners, veterinary staff, and veterinarians.

> **Note:** The user interface is currently under development. This guide
> describes the *intended* workflows based on the implemented domain layer.
> Screens will be added as the presentation layer is built.

---

## 1. Getting Started

### 1.1 Creating an Account

1. Open the CarePaw app.
2. Tap **"Register"**.
3. Enter your email, full name, phone (optional), and a strong password.
4. Select your role: **Pet Owner** (default).
5. Tap **Register**.
6. You'll be logged in automatically and taken to the Home screen.

### 1.2 Logging In

1. Open the app.
2. Tap **"Login"**.
3. Enter your email and password.
4. Tap **Login**.

### 1.3 Forgot Password

1. On the login screen, tap **"Forgot Password?"**
2. Enter your registered email.
3. Follow the reset instructions (to be implemented with backend).

---

## 2. Pet Owner Workflow

### 2.1 Adding Your Pet

1. From Home, navigate to **My Pets** (bottom nav or menu).
2. Tap the **"+"** (Add Pet) button.
3. Fill in:
   - **Name** (required)
   - **Species** — Dog, Cat, Bird, Rabbit, Reptile, Other
   - **Breed** (optional)
   - **Birth Date** (optional — used for age calculation)
   - **Weight (kg)** (optional)
   - **Color** (optional)
   - **Microchip ID** (optional)
   - **Photo** (optional — tap avatar placeholder)
4. Tap **Save**.

Your pet now appears in your list. Tap a pet to view details or edit.

### 2.2 Requesting an Appointment

1. From Home or the pet's detail screen, tap **"Request Appointment"**.
2. Select the **pet** (if multiple).
3. Choose a **service type** (Consultation, Vaccination, Check-up, etc.).
4. Pick a **date and time** from available slots.
5. Enter a **reason** (optional, e.g., "Annual check-up", "Limping on left leg").
6. Tap **Submit Request**.

**Status:** Your request starts as **REQUESTED**. The clinic will review and
change it to **CONFIRMED**, **REJECTED**, or propose a different time.

### 2.3 Viewing Your Appointments

- **Upcoming** — Confirmed appointments, sorted by date.
- **Past** — Completed, cancelled, or no-show appointments.
- Tap an appointment to see details, status, and any notes from the clinic.

### 2.4 Checking Queue Status

When you arrive at the clinic for a confirmed appointment:

1. Tap **Queue** (or the appointment card will show a "Check In" button).
2. Tap **Check In**.
3. You'll receive a **queue number** and see:
   - **Current number being served**
   - **Your position** (how many pets ahead)
   - **Estimated wait time**
   - **Status** (Waiting → Called → In Room → Completed)

You'll receive push notifications when your number is called.

### 2.5 Viewing Pet Medical Records

1. Go to **My Pets** → select a pet.
2. Tap **Medical Records**.
3. Records are organized chronologically with types:
   - **Visit** — Consultation notes, diagnosis, treatment
   - **Vaccination** — Vaccine name, date, next due
   - **Surgery** — Procedure details
   - **Lab Result** — Test outcomes
   - **Prescription** — Medications prescribed
   - **Allergy** — Known allergies
   - **Note** — General notes

> **Privacy:** You only see records for **your own pets**. Veterinarians and
> authorized staff see records for patients they're treating.

### 2.6 Receiving Notifications

Notifications appear in the **Notifications** tab (bell icon). Types:
- **Appointment Reminder** — 24h and 1h before
- **Queue Update** — "You're next!", "Now serving #5"
- **Prescription Ready** — Medication prepared for pickup
- **System** — Clinic announcements, maintenance

Tap a notification to mark as read or view related details.

### 2.7 Editing Your Profile

1. Go to **Settings** → **Profile**.
2. Update name, phone, avatar.
3. Tap **Save**.

---

## 3. Veterinary Staff Workflow

Staff users (role: `STAFF`) have access to clinic operations.

### 3.1 Dashboard

On login, staff see the **Staff Dashboard** with:
- Today's appointments summary
- Current queue status
- Low-stock alerts
- Pending scan reviews

### 3.2 Managing Appointments

1. Navigate to **Appointments**.
2. Filter by **Date**, **Status**, **Veterinarian**.
3. Actions per appointment:
   - **Confirm** — Accept a REQUESTED appointment
   - **Reject** — Decline with reason
   - **Reschedule** — Change date/time
   - **Cancel** — Mark as CANCELLED (with reason)
   - **Check In** — Move to queue (creates QueueEntry)

### 3.3 Managing the Queue

1. Navigate to **Queue**.
2. See all checked-in patients in order.
3. Actions:
   - **Call Next** — Select patient, assign room → status becomes CALLED
   - **Enter Room** — Patient enters exam room → IN_ROOM
   - **Complete** — Visit finished → COMPLETED
   - **Skip** — Patient not present → SKIPPED (with reason)
   - **Reorder** — Drag to adjust position (updates all positions)

### 3.4 Inventory Management

1. Navigate to **Inventory**.
2. **Items tab** — Search, filter by category, see stock levels.
   - **Low Stock** badge on items at or below `minStock`.
   - Tap item to view batches, edit details.
3. **Batches tab** — Expiration tracking.
   - Sort by **Expiration Date**.
   - **Expiring Soon** / **Expired** badges.
4. **Transactions tab** — Full audit trail of every stock movement.

### 3.5 Processing Scans (OCR)

1. Navigate to **Scanning**.
2. Tap **Scan Receipt** or **Scan Medicine Box**.
3. Camera opens — capture clear image.
4. OCR processes automatically; results appear in **Pending Review**.
5. Tap a pending scan to **Review**:
   - Verify/correct medicine name
   - Verify/correct quantity
   - Verify/correct expiration date
   - Verify/correct batch number
6. Tap **Confirm** → Inventory updated via transaction.
7. Tap **Reject** → Discard (with reason).

> **Important:** OCR is **assistive only**. Never auto-applies changes.

---

## 4. Veterinarian Workflow

Veterinarians (role: `VETERINARIAN`) focus on patient care.

### 4.1 Dashboard

On login, veterinarians see the **Vet Dashboard** with:
- Assigned patients for today
- Upcoming appointments
- Pending prescriptions to review

### 4.2 Viewing Patients

1. Navigate to **Patients**.
2. List shows pets with appointments today or assigned to you.
3. Tap a patient to open their **Medical Record**.

### 4.3 Consultation Flow

1. Open patient's record.
2. Review **Medical History** (past visits, vaccinations, lab results).
3. During consultation, tap **Add Record**.
4. Select **Record Type** (Visit, Surgery, Lab Result, etc.).
5. Fill in:
   - **Title** (e.g., "Annual Wellness Exam")
   - **Description** (subjective/objective notes)
   - **Diagnosis**
   - **Treatment Plan**
   - **Medications** (add multiple: name, dosage, frequency, duration)
   - **Attachments** (photos, PDFs — future)
6. Tap **Save** → Record appended to history.

### 4.4 Creating Prescriptions

1. From a Visit record or directly from **Prescriptions** tab.
2. Tap **Add Prescription**.
3. Enter:
   - **Medication Name**
   - **Dosage** (e.g., "10mg")
   - **Frequency** (e.g., "Twice daily")
   - **Duration (days)**
   - **Quantity** (dispensed)
   - **Refills Remaining**
   - **Instructions** (e.g., "Give with food")
4. Tap **Save** → Prescription linked to pet and medical record.

### 4.5 Updating Vaccinations

1. From patient record, tap **Vaccinations**.
2. Tap **Add Vaccination**.
3. Enter vaccine name, manufacturer, batch, date administered, next due date.
4. Tap **Save** → Updates vaccination schedule and triggers reminders.

---

## 5. Administrator Workflow

Admins (role: `ADMIN`) manage the system.

### 5.1 User Management

1. Navigate to **Admin** → **Users**.
2. List all users with role, status, last login.
3. Actions:
   - **Change Role** — Promote/demote
   - **Activate/Deactivate** — Soft delete
   - **View Audit Log** — User's activity

### 5.2 System Settings

1. Navigate to **Admin** → **Settings**.
2. Configure:
   - Clinic name, address, phone
   - Default appointment duration
   - Queue display settings
   - Notification templates
   - Low-stock thresholds

### 5.3 Audit Logs

1. Navigate to **Admin** → **Audit Logs**.
2. Filter by user, action, entity type, date range.
3. View old/new values for sensitive changes.

---

## 6. Troubleshooting

### 6.1 I Can't Log In
- Verify email is correct (case-insensitive).
- Use **"Forgot Password"** to reset.
- Check internet connection (required for future backend sync).
- Contact clinic admin if account may be deactivated.

### 6.2 My Appointment Isn't Showing
- Pull to refresh.
- Check the correct date range (Upcoming vs Past).
- Ensure you're logged in as the correct pet owner.
- Contact the clinic directly.

### 6.3 Queue Position Seems Wrong
- Queue is managed by clinic staff in real-time.
- Position updates automatically when staff reorder or complete patients.
- If concerned, ask front desk staff.

### 6.4 Medication Info Looks Incorrect
- If you scanned a medicine box, verify the details before confirming.
- Contact the clinic if a prescription seems wrong.
- Pharmacists/clinic staff can correct inventory records.

### 6.5 App Crashes or Behaves Oddly
1. Force-close and reopen the app.
2. Check for updates (App Store / Play Store / GitHub releases).
3. Report the issue with:
   - Device / OS version
   - Steps to reproduce
   - Screenshot if possible

---

## 7. FAQ

**Q: Is my pet's data secure?**
A: Yes. Medical records are encrypted at rest, access is role-controlled,
and all sensitive operations are audit-logged.

**Q: Can I share records with another vet?**
A: Export/share functionality is planned. For now, ask your clinic to
provide a summary.

**Q: Does CarePaw work offline?**
A: Yes, the current version uses a local SQLite database. Sync with clinic
backend is planned.

**Q: How do I delete my account?**
A: Contact the clinic administrator. Account deletion is a sensitive
operation that requires verification.

**Q: Can I add multiple pets?**
A: Yes! Tap "Add Pet" as many times as needed. Each pet has its own
records, appointments, and queue entries.

---

## 8. Support

- **In-app:** Settings → Help & Feedback
- **Email:** support@carepaw.example (placeholder)
- **Clinic Front Desk:** For appointment/record questions

---

*CarePaw — Making veterinary care simpler, smarter, and more pet-friendly.*