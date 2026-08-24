# CarePaw — Documentation Index

Welcome to the CarePaw documentation. This folder contains all technical and
user-facing documentation for the project.

---

## 📚 Documentation Files

| File | Description | Audience |
|------|-------------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, design decisions (ADRs), layer boundaries, module map | Developers, Architects, Thesis Panel |
| [DATABASE.md](DATABASE.md) | Complete schema, relationships, integrity rules, indexes, migrations | Developers, DBAs, Thesis Panel |
| [API.md](API.md) | Repository interfaces, entity definitions, error contracts, future REST API | Developers, Thesis Panel |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Local setup, workflows, testing, debugging, common tasks | Developers |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Code standards, PR process, security rules, review guidelines | Contributors |
| [USER_GUIDE.md](USER_GUIDE.md) | End-user workflows for Pet Owners, Staff, Veterinarians, Admins | Users, QA, Thesis Panel |
| [THESIS_SUPPORT.md](THESIS_SUPPORT.md) | Thesis chapter outline, code-to-thesis mapping, defense prep | Students, Advisors |

---

## 🚀 Quick Start

1. **New developer?** → Start with [DEVELOPMENT.md](DEVELOPMENT.md)
2. **Understanding the architecture?** → Read [ARCHITECTURE.md](ARCHITECTURE.md)
3. **Working with the database?** → Reference [DATABASE.md](DATABASE.md)
4. **Implementing a feature?** → Check [API.md](API.md) for contracts
5. **Preparing thesis documentation?** → Use [THESIS_SUPPORT.md](THESIS_SUPPORT.md)
6. **Testing user flows?** → Follow [USER_GUIDE.md](USER_GUIDE.md)

---

## 🏗️ Project Status

| Module | Domain & Data Layer | Presentation Layer | Tests |
|--------|---------------------|-------------------|-------|
| Authentication | ✅ Complete | 📋 Planned | 📋 Planned |
| Users | ✅ Complete | 📋 Planned | 📋 Planned |
| Pets | ✅ Complete | 📋 Planned | 📋 Planned |
| Appointments | ✅ Complete | 📋 Planned | 📋 Planned |
| Queue | ✅ Complete | 📋 Planned | 📋 Planned |
| Medical Records | ✅ Complete | 📋 Planned | 📋 Planned |
| Inventory | ✅ Complete | 📋 Planned | 📋 Planned |
| Scanning/OCR | ✅ Complete | 📋 Planned | 📋 Planned |
| Notifications | ✅ Complete | 📋 Planned | 📋 Planned |

> See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed implementation status.

---

## 🔗 Related Files

- **Project Memory & Rules:** [`../CLAUDE.md`](../CLAUDE.md)
- **Root README:** [`../README.md`](../README.md)
- **Pubspec:** [`../pubspec.yaml`](../pubspec.yaml)
- **Analysis Options:** [`../analysis_options.yaml`](../analysis_options.yaml)

---

## 📝 Documentation Maintenance

- Update docs **in the same PR** as code changes
- Follow the standards in [CONTRIBUTING.md](CONTRIBUTING.md) Section 7
- Run `flutter analyze` and `flutter test` before merging

---

*CarePaw — Smart Veterinary Patient Management System*