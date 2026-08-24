# CarePaw — Contributing Guide

Thank you for contributing to CarePaw! This document outlines the standards,
workflow, and expectations for contributors.

---

## 1. Code of Conduct

By participating, you agree to uphold a respectful, inclusive, and
professional environment. Harassment, discrimination, or disruptive behavior
will not be tolerated.

---

## 2. Getting Started

1. Read the [Development Guide](DEVELOPMENT.md) for setup instructions.
2. Familiarize yourself with the [Architecture](ARCHITECTURE.md) and
   [Database](DATABASE.md) documentation.
3. Review the project [CLAUDE.md](../CLAUDE.md) for the core rules and
   development philosophy.

---

## 3. Development Workflow

### 3.1 Branching

```bash
# Start from main
git checkout main
git pull origin main

# Create a feature branch
git checkout -b feat/short-descriptive-name

# Or fix branch
git checkout -b fix/short-descriptive-name
```

**Branch naming:** `type/short-kebab-case-description`

| Type | Example |
|------|---------|
| `feat/` | `feat/appointments-add-recurring` |
| `fix/` | `fix/queue-position-recalc` |
| `docs/` | `docs/update-architecture-adr` |
| `refactor/` | `refactor/extract-validators` |
| `test/` | `test/add-inventory-contract-tests` |
| `chore/` | `chore/upgrade-drift` |

### 3.2 Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>

<body — optional, wrap at 72 chars>

<footer — optional, e.g. Closes #123>
```

**Types:**
- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — restructuring, no behavior change
- `test` — adding tests
- `chore` — build, deps, config
- `perf` — performance improvement
- `security` — security fix

**Examples:**
```
feat(pets): add microchip field to pet entity

fix(queue): prevent duplicate check-in for same appointment

docs(architecture): add ADR-006 for notification channels

refactor(inventory): extract transaction service

test(appointments): add status transition validation tests
```

### 3.3 Pull Requests

1. Push your branch: `git push origin feat/your-feature`
2. Open a PR against `main`
3. Fill out the PR template (see below)
4. Ensure CI passes (analyze, tests)
5. Request review from a maintainer

**PR Title:** Same format as commit: `type(scope): summary`

**PR Description Template:**
```markdown
## Summary
Brief description of what this PR does.

## Type
- [ ] Feature
- [ ] Bug Fix
- [ ] Documentation
- [ ] Refactor
- [ ] Test
- [ ] Chore

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed (describe)

## Screenshots (if UI)
| Before | After |
|--------|-------|
| ![before](url) | ![after](url) |

## Checklist
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `flutter pub run build_runner build` succeeds
- [ ] No hardcoded secrets
- [ ] Documentation updated (README, ARCHITECTURE, DATABASE, API, DEVELOPMENT)
- [ ] Migration script added (if schema changed)
```

---

## 4. Code Standards

### 4.1 Architecture Compliance

- **Domain layer purity:** No Drift, no Flutter, no HTTP in `domain/`
- **Repository pattern:** Interface in `domain/`, implementation in `data/`
- **Error handling:** Use `Failure` hierarchy, never throw exceptions across layers
- **Authorization:** Check permissions in repository/usecase, never in UI only

### 4.2 Dart Style

- Run `flutter analyze` — zero warnings required
- Run `dart format .` before committing
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `equatable` for value objects (entities, failures, params)
- Prefer `const` constructors where possible

### 4.3 Naming Conventions

| Element | Convention |
|---------|------------|
| Files | `snake_case.dart` |
| Classes, Enums, Extensions | `PascalCase` |
| Variables, Functions, Parameters | `camelCase` |
| Constants (const) | `camelCase` or `SCREAMING_SNAKE_CASE` |
| Private (library) | `_leadingUnderscore` |

### 4.4 Dependencies

- Check `pubspec.yaml` before adding a new package
- Prefer existing packages in the project
- Justify new dependencies in PR description

---

## 5. Testing Requirements

### 5.1 Minimum Coverage

| Change Type | Required Tests |
|-------------|----------------|
| New repository method | Unit test (fake + Drift impl) |
| New BLoC | BlocTest for each event/state |
| New widget | Widget test |
| New feature flow | Integration test |
| Bug fix | Regression test |

### 5.2 Running Tests

```bash
# All tests
flutter test

# Coverage
flutter test --coverage
# View: genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

### 5.3 Test Organization

```
test/
├── unit/
│   ├── core/
│   └── features/<feature>/
├── widget/
└── integration_test/
```

---

## 6. Security Rules

**NEVER:**
- Hardcode passwords, API keys, or tokens
- Commit `.env` or any secret file
- Log passwords, tokens, or PII
- Trust client-side authorization
- Trust OCR output without human confirmation
- Allow arbitrary file uploads
- Expose private medical records
- Give every user admin privileges

**ALWAYS:**
- Use `flutter_secure_storage` for sensitive values
- Validate input client-side AND via DB constraints
- Log sensitive operations to `audit_logs`
- Enforce RBAC in repository layer
- Use transactions for multi-table writes

---

## 7. Documentation

Update documentation **in the same PR** as code changes:

| Document | When to Update |
|----------|----------------|
| `README.md` | New feature, setup change, version bump |
| `ARCHITECTURE.md` | New ADR, layer change, module boundary |
| `DATABASE.md` | Schema change, new table, index, migration |
| `API.md` | New repository method, entity field, failure type |
| `DEVELOPMENT.md` | New workflow, tool, troubleshooting tip |
| `USER_GUIDE.md` | User-facing feature change |

---

## 8. Release Process

1. Version bump in `pubspec.yaml` (semver: `major.minor.patch`)
2. Update `CHANGELOG.md` (if exists) or PR description
3. Tag: `git tag -a v0.x.x -m "Release v0.x.x"`
4. Push tag: `git push origin v0.x.x`
5. CI builds artifacts (APK, IPA, Web)

---

## 9. Review Guidelines

### For Authors
- Keep PRs focused and reasonably sized (< 500 lines ideal)
- Self-review before requesting review
- Respond to feedback promptly

### For Reviewers
- Check architecture compliance
- Verify tests cover new logic
- Confirm no security violations
- Ensure documentation is updated
- Approve when confident; request changes otherwise

---

## 10. Questions?

- Check existing issues and discussions
- Read the [CLAUDE.md](../CLAUDE.md) project memory
- Ask in the PR or open a discussion

---

Thank you for making CarePaw better! 🐾