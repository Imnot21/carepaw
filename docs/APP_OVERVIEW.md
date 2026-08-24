# CarePaw — Complete App Overview (Layman's Guide)

*Everything you need to understand how CarePaw works, who can do what, and how to get started.*

---

## 🎯 What Is CarePaw?

**CarePaw is a smart veterinary clinic management system.** Think of it as a digital command center for a vet clinic that connects:

- **Pet owners** — Book appointments, track queue, view pet health records
- **Veterinarians** — See patients, write medical notes, prescribe meds
- **Clinic staff** — Manage appointments, run the queue, handle inventory
- **Admins** — Manage users, settings, view audit logs

Everything runs on **one shared database** so data stays in sync across all roles.

---

## 👥 User Roles & What They Can Do

| Role | Who It's For | Main Access |
|------|--------------|-------------|
| **Pet Owner** | Regular people with pets | Book appointments, add pets, check queue, view own pets' records |
| **Veterinarian** | Licensed vets | See assigned patients, write medical records, create prescriptions, update vaccinations |
| **Staff** | Front desk, techs, nurses | Manage ALL appointments, run the queue, handle inventory, process OCR scans |
| **Admin** | Clinic owner/manager | Manage users & roles, clinic settings, view audit logs, everything |

> **Key Rule:** The app enforces these roles **automatically**. A pet owner *cannot* access the staff queue. A staff member *cannot* write medical diagnoses. The database and code both enforce this.

---

## 🔐 How to Create Accounts for Each Role

### For Pet Owners (Self-Service)
1. Open the app → Tap **"Register"**
2. Fill in: Email, Full Name, Phone (optional), Password
3. **Role defaults to "Pet Owner"** — no choice needed
4. Tap Register → You're logged in!

### For Staff, Vets, Admins (Admin-Created)
**These roles CANNOT self-register.** An Admin must create them:

1. **Log in as Admin** (see below for first admin)
2. Go to **Admin → Users → Add User**
3. Fill in their details + **select their Role** (Staff / Veterinarian / Admin)
4. Set a temporary password → Tell them to log in and change it

### Creating the FIRST Admin (Database Method)
Since there's no admin to create the first admin, you have two options:

**Option A: Direct Database Insert (Easiest)**
```sql
-- Open the SQLite database (see "Viewing the Database" below)
-- Run this to create an admin user:
INSERT INTO users (email, password_hash, full_name, role, is_active, created_at, updated_at)
VALUES (
  'admin@clinic.com',
  '$2b$12$...hashed_password...',  -- Use a bcrypt tool to hash "AdminPass123!"
  'Clinic Admin',
  'ADMIN',
  1,
  datetime('now'),
  datetime('now')
);
```

**Option B: Temporarily Allow Admin Registration in Code**
1. Open `lib/features/authentication/presentation/pages/register_page.dart`
2. Find line 85: `role: UserRole.petOwner,`
3. Change to a dropdown that lets you pick Admin (for setup only)
4. Register your admin account
5. **Change it back immediately!**

---

## 🗄️ How to View Your Database

The app uses **SQLite** (a single file database). Here's how to inspect it:

### Option 1: DB Browser for SQLite (Free GUI — Recommended)
1. Download: https://sqlitebrowser.org/
2. Find the database file:
   - **Android:** `/data/data/com.carepaw.app/databases/carepaw.sqlite`
   - **iOS:** Use Xcode Devices window → Download container
   - **Desktop (dev):** `build/<platform>/data/user/.../carepaw.sqlite`
   - **Flutter debug:** Print path with `getApplicationDocumentsDirectory()`
3. Open in DB Browser → Browse Data tab → Select any table

### Option 2: Command Line (sqlite3)
```bash
# Find the file first:
find . -name "carepaw.sqlite" 2>/dev/null

# Then open it:
sqlite3 /path/to/carepaw.sqlite

# Useful commands:
.tables                    -- List all tables
.schema users              -- See table structure
SELECT * FROM users;       -- View all users
SELECT * FROM pets;        -- View all pets
SELECT * FROM queue_entries; -- View queue
.quit                      -- Exit
```

### Option 3: VS Code Extension (During Development)
1. Install "SQLite" or "SQLite Viewer" extension in VS Code
2. Right-click the `.sqlite` file → "Open Database"
3. Run queries in the editor

### Key Tables to Check
| Table | What You'll See |
|-------|-----------------|
| `users` | All accounts + roles |
| `pets` | All pets + owner links |
| `appointments` | All bookings + status |
| `queue_entries` | Live queue state |
| `medical_records` | Health history |
| `inventory_items` | Medicine catalog |
| `inventory_transactions` | Every stock movement |
| `audit_logs` | Who did what, when |

---

## ⚡ Quick Actions — Role-Based

### Pet Owner Quick Actions
| Action | Where | Result |
|--------|-------|--------|
| Add Pet | Home → My Pets → + | Creates pet profile linked to you |
| Book Appointment | Home → Book Appointment | Creates REQUESTED appointment |
| Check In | Appointment card → Check In | Adds to live queue, gets number |
| View Queue | Queue tab | Shows position, wait time, status |
| View Records | My Pets → [Pet] → Records | Shows only YOUR pets' history |

### Staff Quick Actions (Queue Page)
| Action | When Available | What It Does |
|--------|----------------|--------------|
| **Call Next** | Patient is WAITING | Moves to CALLED, assigns room |
| **Move to Room** | Patient is CALLED | Moves to IN_ROOM, starts timer |
| **Complete** | Patient is IN_ROOM | Marks COMPLETED, removes from queue |
| **Skip** | WAITING or CALLED | Marks SKIPPED (no-show), repositions |
| **Reorder** | Any time | Drag to change queue order |
| **Refresh** | Any time | Reloads from database |

> **Staff see ALL patients.** Pet owners only see THEIR pets.

### Veterinarian Quick Actions
| Action | Where | Result |
|--------|-------|--------|
| View Patients | Dashboard / Patients tab | Today's assigned pets |
| Open Record | Tap patient | Full medical history |
| Add Visit Record | In patient record | Creates VISIT entry |
| Add Prescription | In visit record | Creates prescription linked to pet |
| Add Vaccination | Vaccinations tab | Updates vaccine schedule |

### Admin Quick Actions
| Action | Where | Result |
|--------|-------|--------|
| Manage Users | Admin → Users | Change roles, activate/deactivate |
| View Audit Logs | Admin → Audit Logs | Search all system activity |
| Clinic Settings | Admin → Settings | Name, hours, defaults |
| View All Data | Any feature | No restrictions |

---

## 🔄 Core Workflows (How Data Flows)

### 1. Appointment → Queue Flow
```
Pet Owner          Clinic Staff
     │                  │
     ├─ Request Appt ──►│ (status: REQUESTED)
     │                  │
     │◄── Confirm ──────┤ (status: CONFIRMED)
     │                  │
     ├─ Check In ──────►│ (creates QueueEntry, status: WAITING)
     │                  │
     │                  ├─ Call Next ──► (status: CALLED, room assigned)
     │                  │
     │◄── Notified ──────┤ "Your number is called!"
     │                  │
     │                  ├─ Move to Room (status: IN_ROOM)
     │                  │
     │                  ├─ Vet sees patient
     │                  │
     │                  ├─ Complete Visit (status: COMPLETED)
     │                  │
     │◄── Done ──────────┤
```

### 2. Medical Record Flow (Append-Only!)
```
Vet opens patient → Sees history (read-only past records)
       │
       ├─ Adds new Visit record
       │    ├─ Title, Description, Diagnosis, Treatment
       │    ├─ Adds Medications (multiple)
       │    └─ Adds Attachments (future)
       │
       └─ Saves → NEW record appended
            ├─ Previous records NEVER modified
            └─ Audit log: "Vet X created Visit record for Pet Y"
```

### 3. Inventory Scan Flow (Human-Verified!)
```
Staff scans medicine box/receipt
       │
       ▼
OCR extracts text (name, qty, expiry, batch)
       │
       ▼
Results show in "Pending Review" — NOT auto-applied!
       │
       ▼
Staff reviews each field ✓ or ✗ corrects
       │
       ▼
Tap "Confirm" → Creates InventoryTransaction (type: IN)
       │
       ▼
Stock updated + Audit trail: "Staff X added 50 units of Medicine Y via scan Z"
```

---

## 🏗️ Architecture in Simple Terms

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                           │
├──────────────┬──────────────┬──────────────┬────────────────┤
│  Pet Owner   │ Veterinarian │   Staff      │    Admin       │
│   Features   │   Features   │  Features    │   Features     │
└──────┬───────┴──────┬───────┴──────┬───────┴───────┬────────┘
       │              │              │               │
       └──────────────┼──────────────┼───────────────┘
                      ▼
           ┌─────────────────────┐
           │   BLoC State Mgmt   │  (Business logic, coordinates data)
           └──────────┬──────────┘
                      ▼
           ┌─────────────────────┐
           │   Repositories      │  (Abstract data access)
           └──────────┬──────────┘
                      ▼
           ┌─────────────────────┐
           │   Drift (SQLite)    │  (Local database on device)
           └─────────────────────┘
```

**Key Principles:**
- **Clean Architecture** — UI doesn't talk to database directly
- **Repository Pattern** — Swappable data sources (local now, API later)
- **BLoC** — State management (loading, error, data)
- **Role checks happen in BLoC + Database** — Not just UI hiding buttons

---

## 📱 Current App State

| Feature | Status |
|---------|--------|
| **Database Schema** | ✅ Complete (13 tables, FKs, indexes) |
| **Auth (Login/Register)** | ✅ Complete (JWT + local storage) |
| **Pet Management** | ✅ Complete |
| **Appointments** | ✅ Domain done, UI in progress |
| **Queue Management** | ✅ Domain + Staff UI done |
| **Medical Records** | ✅ Domain done, UI in progress |
| **Inventory** | ✅ Domain done, UI in progress |
| **OCR/Scanning** | 📋 Planned (ML Kit / Google Vision) |
| **Notifications** | 📋 Planned (local + push) |
| **Admin Panel** | 📋 Planned |

---

## 🚀 Getting Started Checklist

### For Development/Testing
1. **Clone repo** → `flutter pub get` → `flutter run`
2. **Register as Pet Owner** → Test booking flow
3. **Create Admin in DB** (see above) → Log in as Admin
4. **Create Staff/Vet accounts** via Admin panel
5. **Log in as each role** → Test their features

### For Demo/Thesis Presentation
1. **Pre-create accounts:**
   - `owner@demo.com` / `OwnerPass123!` (Pet Owner)
   - `vet@demo.com` / `VetPass123!` (Veterinarian)
   - `staff@demo.com` / `StaffPass123!` (Staff)
   - `admin@demo.com` / `AdminPass123!` (Admin)
2. **Pre-add data:**
   - 2-3 pets for owner
   - 2-3 appointments (different statuses)
   - 3-4 queue entries (waiting, called, in-room)
   - 5-6 medical records (visit, vaccination, lab)
   - 10+ inventory items with batches
3. **Show role switching:** Log out → Log in as different role → Show different UI

---

## 🔍 Common Questions

### "Can a pet owner see other pets' records?"
**No.** The `MedicalRecordsRepository` filters by `pet.ownerId == currentUser.id`. Even if you hack the UI, the database query returns empty.

### "Can staff write medical diagnoses?"
**No.** The `MedicalRecordsRepository.save()` checks `user.role == VETERINARIAN || user.role == ADMIN`. Staff get a permission error.

### "What happens if two staff tap 'Call Next' at the same time?"
The `QueueRepository.callNext()` runs in a **database transaction**. Only one succeeds; the other gets "No waiting patients" error.

### "Is the queue real-time?"
Yes! The `QueueBloc` uses `repository.watchCurrentQueue()` which returns a **Stream**. Any database change → all connected UIs update instantly.

### "Can I run this on multiple devices?"
Currently **local-only** (each device has its own SQLite file). Multi-device sync requires a backend API (planned).

### "How do I reset the database for testing?"
Delete the app data (uninstall/reinstall) or delete the `.sqlite` file. On next run, Drift creates fresh tables.

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| `USER_GUIDE.md` | Step-by-step workflows per role |
| `DATABASE.md` | Full schema, relationships, indexes |
| `ARCHITECTURE.md` | Technical architecture decisions |
| `DEVELOPMENT.md` | Setup, coding standards, testing |
| `THESIS_SUPPORT.md` | Documentation for thesis defense |

---

## 💡 Quick Reference: Role Permissions Matrix

| Feature | Pet Owner | Veterinarian | Staff | Admin |
|---------|-----------|--------------|-------|-------|
| Register self | ✅ | ❌ | ❌ | ❌ |
| Create users | ❌ | ❌ | ❌ | ✅ |
| Add own pets | ✅ | ❌ | ❌ | ✅ |
| View all pets | ❌ | ✅ (assigned) | ✅ | ✅ |
| Book appointments | ✅ | ❌ | ✅ | ✅ |
| Confirm/reject appts | ❌ | ❌ | ✅ | ✅ |
| Check in patients | Own only | ❌ | ✅ | ✅ |
| Manage queue | ❌ | ❌ | ✅ | ✅ |
| Write medical records | ❌ | ✅ | ❌ | ✅ |
| Create prescriptions | ❌ | ✅ | ❌ | ✅ |
| Manage inventory | ❌ | ❌ | ✅ | ✅ |
| Process OCR scans | ❌ | ❌ | ✅ | ✅ |
| View audit logs | ❌ | ❌ | ❌ | ✅ |
| Change clinic settings | ❌ | ❌ | ❌ | ✅ |

---

*CarePaw — Making veterinary care simpler, smarter, and more pet-friendly.*