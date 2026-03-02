# Deep Code Audit — Pre-PR Submission

## Purpose
Automated deep-dive code review that catches real bugs before they hit PR review. This replaces surface-level checklists with the same exhaustive file-by-file analysis that catches nil guard bugs, force unwraps, race conditions, and code smell.

**This is NOT a checklist to skim. This is an execution plan. Run it.**

---

## Phase 1: Scope the Diff

Identify every file changed in this PR against the base branch.

```bash
# Get the base branch (usually develop)
git diff develop...HEAD --stat

# Get the full list of changed files
git diff develop...HEAD --name-only
```

Categorize changed files into two groups:
- **View files**: Any file in `Views/`, `Home/HomeView.swift`, `Exercise/` that contains SwiftUI views
- **Non-view files**: Services, ViewModels, Models, Mappers, Extensions, DesignSystem, Tests, Mocks

---

## Phase 2: Deep Audit (Parallel Agents)

Launch TWO parallel audit agents. Each agent must READ EVERY changed file in its group — no skipping, no sampling. Each agent produces a ranked list of every issue found.

### Agent 1: View Files Audit

Read every changed view file. For EACH file, check for ALL of the following:

**Crash Vectors**
- Force unwraps (`!`) — every single one, even in previews
- Unsafe array indexing without bounds checks (including negative index checks)
- Missing nil guards that lead to incorrect behavior

**Loading State Bugs**
- Views that show "no data" / empty state messages BEFORE data has loaded (must check `isLoading` before showing empty state)
- Views that check `.isEmpty` on `onAppear` without a `hasLoaded` flag (causes redundant fetches when data is genuinely empty)
- Missing `ProgressView` for initial load states

**SwiftUI Antipatterns**
- Views presented in `.sheet()` or `.fullScreenCover()` that use `.navigationTitle` / `.toolbar` without being wrapped in `NavigationStack`
- `.fullScreenCover` / `.sheet` that can show blank content if the bound data is nil (race condition)
- `@ObservedObject` used with singleton default values (should be `@EnvironmentObject` or `let`)
- Sheet/cover modifiers attached to inner views instead of the outermost container
- Potential double-dismiss issues in nested navigation/sheet flows
- Missing data reload after edit sheet dismissal (`onDismiss` handler)

**Design System Compliance**
- Magic numbers for spacing instead of `AppSpacing` constants
- Magic numbers for corner radius instead of `AppCornerRadius` constants
- Hardcoded colors that should use design tokens
- `RelativeDateTimeFormatter` or other expensive formatters created inside computed properties (should be `static let`)

**Code Smell**
- Business logic in View structs (belongs in ViewModel)
- Duplicated view builders across multiple files (should be extracted to reusable components)
- Duplicated error alert boilerplate (should be a view modifier)
- Free functions in global scope (should be extensions or static methods)
- Non-deterministic `String.hashValue` used for visual elements (not stable across launches)

**Data Integrity**
- Silent fallback defaults that mask missing data (e.g., defaulting to `.chest` muscle group, defaulting `nil` notes to "Failure")
- Optional chaining that silently drops important information

### Agent 2: Non-View Files Audit

Read every changed non-view file. For EACH file, check for ALL of the following:

**Crash Vectors**
- Force unwraps (`!`) in production code — `URLComponents(...)!`, `as!`, `cursor!`
- Missing nil guards in decode chains (e.g., `APIEnvelope` with all-optional fields succeeding decode on any JSON, returning `nil` data without falling through to fallback decoders)
- Force unwraps in test helpers (`MockURLProtocol`, etc.) that crash entire test suite on failure

**Code Duplication**
- Identical private types across files (e.g., `APIEnvelope` duplicated in two services)
- Identical helper methods across files (e.g., `decodeFailure`, `parseDate`)
- Identical structural patterns that should be generic helpers
- `ISO8601DateFormatter()` or other formatters created repeatedly instead of shared

**Thread Safety**
- `@MainActor`-isolated properties read from `@Sendable` closures without capturing first
- `@unchecked Sendable` on classes with mutable `var` properties and no synchronization
- `withCheckedContinuation` that can hang if the task is cancelled before `resume()` is called
- Redundant `await MainActor.run {}` inside already-`@MainActor` classes (use `TaskManager.runOnMain` if available)

**Decoding Safety**
- `try?` decode chains that silently discard the actual error from the correct format, making debugging impossible
- Optional DTO fields (e.g., `exercises: [DTO]?`) that silently become empty arrays in domain models — consumers can't distinguish "not loaded" from "actually empty"
- Date parsing that silently defaults to `Date()` on malformed input

**Error Handling Consistency**
- ViewModels that swallow errors silently vs. ones that set `self.error` — should be consistent
- Template/data loading failures silently ignored via `try?` without any user indication
- Error types that wrap decode errors as `.unknown` (loses error specificity)

**Model Safety**
- `Equatable`/`Hashable` that only compare `id` — SwiftUI won't detect property changes for re-render
- Computed properties (e.g., `progress`) that don't guard against empty collections before doing math
- Missing `final class` on ViewModels (inconsistent, allows unintended subclassing)

**Memory**
- `TaskManager` or similar that stores completed tasks indefinitely without cleanup
- Retain cycle potential in closures (verify `[weak self]` usage)

---

## Phase 3: Triage and Fix

After both agents report, consolidate all issues into a single ranked list:

**Severity Levels:**
- **HIGH**: Will crash, hang, or show blank/broken UI in production
- **MEDIUM**: Incorrect behavior, stale data, misleading UI, thread safety risk
- **LOW**: Code smell, duplication, inconsistency, performance (non-blocking)

**Fix order:**
1. ALL HIGH issues — no exceptions
2. ALL MEDIUM issues — these are what external reviewers flag
3. LOW issues — fix what's reasonable without scope creep

For each fix:
- State the exact file, line number, and what's wrong
- Apply the fix
- Move to the next issue

Do NOT batch-read files you've already read. Do NOT re-audit after fixes. Fix everything in one pass.

---

## Phase 4: Build and Test

```bash
# Build
xcodebuild -project Nippardation.xcodeproj -scheme Nippardation -sdk iphonesimulator build

# Run all unit tests
xcodebuild test -project Nippardation.xcodeproj -scheme Nippardation \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:NippardationTests
```

Both MUST pass. If build fails, fix and rebuild. If tests fail, fix and rerun.

---

## Phase 5: PR Size Validation

```bash
git diff --stat develop...HEAD | tail -1
```

- **Hard limit**: 1000 lines changed
- If over, split before proceeding — do NOT open an oversized PR

---

## Phase 6: Summary

Before committing/pushing, produce a summary of every fix applied:

```
## Fixes Applied

### HIGH
- [file:line] Description of what was wrong and what was fixed

### MEDIUM
- [file:line] Description of what was wrong and what was fixed

### LOW
- [file:line] Description of what was wrong and what was fixed
```

This summary goes in the commit message body and can be referenced in PR comments.

---

## What This Catches That Checklists Don't

- Decode methods that return `nil` prematurely because `APIEnvelope` with all-optional fields succeeds on any JSON
- Views that flash "no data" messages before the first network call completes
- `NavigationStack` missing from sheet-presented views (invisible toolbar/title)
- `fullScreenCover` that opens blank when bound state is nil
- `String.hashValue` used for colors (randomized per launch in Swift 4.2+)
- Formatters allocated on every SwiftUI render pass
- `@MainActor` properties read from `@Sendable` closures without capture
- `withCheckedContinuation` that hangs if the wrapped task is cancelled
- Struct `Equatable` that only checks `id` (SwiftUI won't re-render on property changes)
- Duplicated private types across service files that diverge over time

**These are the bugs that slip through checkbox reviews and get flagged by automated PR bots. This audit catches them first.**
