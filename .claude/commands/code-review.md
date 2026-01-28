# iOS Pre-PR Submission Checklist

## Purpose
Ruthlessly thorough verification that code is production-ready before opening a PR. This is the FINAL gate before submission. If ANY check fails, DO NOT open the PR.

## Execution Order

This checklist MUST be executed in order. Do not skip steps. Do not proceed if any step fails.

---

## 1. Branch Verification

**Check current branch state**
```bash
# Verify you're not on main
current_branch=$(git branch --show-current)
if [ "$current_branch" = "main" ]; then
    echo "ERROR: Cannot submit PR from main branch"
    exit 1
fi

# Verify branch is up to date with remote
git fetch origin
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
if [ $LOCAL != $REMOTE ]; then
    echo "ERROR: Branch out of sync with remote. Push or pull required."
    exit 1
fi
```

**Verify commit messages**
- All commits have descriptive messages (not "wip", "fix", "update")
- Commits are logical units of work
- No merge commits (should be rebased)

---

## 2. Code Compilation

**Full clean build**
```bash
# Clean build folder
xcodebuild clean -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for simulator
xcodebuild build -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15' -quiet

# Build for device (if applicable)
xcodebuild build -scheme Nippardation -destination 'generic/platform=iOS' -quiet
```

**Build verification**
- [ ] No compilation errors
- [ ] No warnings (zero-warning policy)
- [ ] No deprecated API usage
- [ ] All asset references resolve
- [ ] All string localizations exist

---

## 3. Code Quality & Style

**SwiftLint**
```bash
# Run SwiftLint with strict rules
swiftlint lint --strict --quiet

# If violations exist, show them
swiftlint lint
```

**Manual code quality checks**
- [ ] No force-unwraps without explicit documented reason
- [ ] No force-try without proper justification
- [ ] No `as!` force casts
- [ ] No hardcoded strings (use localization)
- [ ] No magic numbers (use named constants)
- [ ] No commented-out code blocks
- [ ] No `print()` statements (use proper logging)
- [ ] No TODO/FIXME comments (create issues instead)
- [ ] Proper access control (internal by default, public only when needed)
- [ ] No retain cycles (check weak/unowned references)

**Architecture compliance**
- [ ] MVVM structure maintained (no business logic in views)
- [ ] Single Responsibility Principle followed
- [ ] Dependencies properly injected (no singletons unless justified)
- [ ] Protocols used for abstraction where appropriate
- [ ] No massive view controllers (>300 lines)
- [ ] No massive view models (>400 lines)

---

## 4. Test Suite Execution

**Run the testing skill first**
```bash
# If tests don't exist or fail, invoke the testing skill
# This should add/update tests and verify they pass
```

**Full test suite**
```bash
# Run all unit tests
xcodebuild test -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NippardationTests
```

**Test verification**
- [ ] All tests pass
- [ ] No skipped tests
- [ ] No flaky tests (run twice if suspicious)
- [ ] Test coverage meets minimums:
  - New ViewModels: 90%+
  - New Services/Repositories: 85%+
  - New Models: 80%+
- [ ] No tests with sleep() or arbitrary delays
- [ ] All async tests properly use expectations or async/await

---

## 5. Security Audit

**API Keys & Secrets**
```bash
# Check for exposed secrets
grep -r "API_KEY" --include="*.swift" .
grep -r "api_key" --include="*.swift" .
grep -r "secret" --include="*.swift" .
grep -r "password" --include="*.swift" .
grep -r "token" --include="*.swift" .
```

**Security checklist**
- [ ] No API keys hardcoded in source
- [ ] No secrets in git history
- [ ] Keychain used for sensitive data
- [ ] HTTPS enforced for all network calls
- [ ] Certificate pinning implemented (if required)
- [ ] User input properly validated/sanitized
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevention in web views

**Data protection**
- [ ] User data encrypted at rest
- [ ] Sensitive data not logged
- [ ] Proper error messages (no internal details exposed)
- [ ] Authentication tokens refreshed properly
- [ ] Biometric authentication working correctly

---

## 6. Memory & Performance

**Memory leaks**
```bash
# Run with Instruments if significant memory changes
# Manually verify in Xcode Memory Graph Debugger
```

**Performance checks**
- [ ] No synchronous operations on main thread
- [ ] Images properly sized/optimized
- [ ] Large lists use lazy loading
- [ ] Network requests properly cancelled on view dismissal
- [ ] No memory leaks in view controllers
- [ ] Combine subscriptions properly cancelled

**Startup performance**
- [ ] App launch time < 2 seconds
- [ ] Initial view appears quickly
- [ ] No blocking operations in application:didFinishLaunching

---

## 7. UI/UX Verification

**Build and run manually**
```bash
# Launch app on simulator
xcodebuild build -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15'
# Then manually open simulator and run app
```

**Visual verification**
- [ ] UI renders correctly on iPhone SE (smallest screen)
- [ ] UI renders correctly on iPhone 15 Pro Max (largest screen)
- [ ] Dark mode works correctly
- [ ] Safe area insets respected
- [ ] Navigation flows work as expected
- [ ] All animations smooth (60fps)
- [ ] No visual glitches or layout issues
- [ ] Loading states display properly
- [ ] Error states display properly
- [ ] Empty states display properly

**Accessibility (manual verification)**
- [ ] VoiceOver labels present and accurate
- [ ] Dynamic Type support
- [ ] Sufficient color contrast
- [ ] Interactive elements minimum 44pt tap target
- [ ] Focus order logical

---

## 8. Data & State Management

**Persistence verification**
- [ ] Data saves correctly
- [ ] Data loads correctly
- [ ] Database migrations work (test fresh install + upgrade)
- [ ] Core Data relationships intact
- [ ] No data loss scenarios

**State management**
- [ ] App state persists across backgrounds
- [ ] Navigation state properly managed
- [ ] No inconsistent states possible
- [ ] Race conditions handled
- [ ] Optimistic updates work correctly

---

## 9. Error Handling

**Error scenarios**
- [ ] Network failures handled gracefully
- [ ] Offline mode works (if applicable)
- [ ] Invalid data handled without crashes
- [ ] User-facing error messages are clear and actionable
- [ ] Errors logged appropriately for debugging
- [ ] Recovery actions provided where possible
- [ ] Errors in ViewModels are displayed to users (via alerts, toasts, etc.)
- [ ] Async operation failures don't leave UI in broken state

**Edge cases**
- [ ] Empty data sets handled
- [ ] Maximum data sets handled
- [ ] Rapid user interactions handled
- [ ] Interrupted operations handled
- [ ] Background/foreground transitions handled

---

## 9.5. Crash Prevention (CRITICAL)

**This section catches crashes that would take down the app in production. Review CAREFULLY.**

**Forbidden crash-inducing patterns**
```bash
# Search for preconditions and assertions (should be removed or have fallbacks)
grep -rn "precondition\(" --include="*.swift" .
grep -rn "preconditionFailure\(" --include="*.swift" .
grep -rn "fatalError\(" --include="*.swift" .
grep -rn "assert\(" --include="*.swift" .
grep -rn "assertionFailure\(" --include="*.swift" .
```

**Precondition and assertion checklist**
- [ ] NO `precondition()` calls in production code (crashes in release builds)
- [ ] NO `preconditionFailure()` calls in production code
- [ ] `fatalError()` only used in truly unrecoverable situations (Core Data model init, required init)
- [ ] `assert()` only used for debug-time invariant checking (safe in release)
- [ ] `assertionFailure()` only used for debug-time impossible states

**Force unwrap safety**
```bash
# Find force unwraps (! operator)
grep -rn "!\." --include="*.swift" .
grep -rn "!\[" --include="*.swift" .
grep -rn "as!" --include="*.swift" .
```

- [ ] NO force unwraps (`!`) without documented safety guarantee
- [ ] NO force casts (`as!`) without proven type safety
- [ ] All force unwraps on constants (URLs, UUIDs) are verified at compile-time
- [ ] Optional binding (`if let`, `guard let`) used instead of force unwrap

**Array bounds safety**
```bash
# Find array subscript access patterns
grep -rn "\[index\]" --include="*.swift" .
grep -rn "\[i\]" --include="*.swift" .
```

- [ ] All array access has bounds checking (or uses safe methods like `.first`, `.last`)
- [ ] `indices.contains(index)` or `guard index >= 0 && index < array.count` before access
- [ ] ForEach with indices uses enumerated() pattern safely
- [ ] SwiftUI Bindings to arrays check bounds before access (especially when array can shrink)
- [ ] No array access after potential modification without re-validation

**Empty collection edge cases**
- [ ] `.first!` never used (use `.first` with optional handling)
- [ ] `.last!` never used (use `.last` with optional handling)
- [ ] Empty arrays handled gracefully (show empty state, not crash)
- [ ] Division by `count` checks for zero first
- [ ] `randomElement()!` not used (returns optional)

**Optional chaining patterns**
- [ ] Computed properties return optionals when data may not exist
- [ ] Callers handle nil cases from optional-returning methods
- [ ] No assumption that optional will "always" have a value

**SwiftUI-specific crash vectors**
- [ ] Binding getters/setters have bounds checks for array indices
- [ ] State mutations don't happen during view body evaluation
- [ ] Sheet/NavigationLink destinations don't assume data exists
- [ ] ForEach with dynamic data uses stable identifiers

**Concurrency safety**
- [ ] No race conditions between array modifications and reads
- [ ] MainActor isolation for UI state mutations
- [ ] Task cancellation doesn't leave state in inconsistent condition

**Example fixes for common issues:**

```swift
// BAD: Will crash if array is empty
var currentItem: Item {
    precondition(!items.isEmpty, "Items should not be empty")
    return items[currentIndex]
}

// GOOD: Returns optional, callers handle nil
var currentItem: Item? {
    guard currentIndex >= 0 && currentIndex < items.count else { return nil }
    return items[currentIndex]
}

// BAD: Binding can crash if array shrinks
Binding(
    get: { viewModel.items[index] },
    set: { viewModel.items[index] = $0 }
)

// GOOD: Safe binding with bounds check
Binding(
    get: { index < viewModel.items.count ? viewModel.items[index] : defaultValue },
    set: { if index < viewModel.items.count { viewModel.items[index] = $0 } }
)
```

---

## 10. Dependencies & Integrations

**Third-party libraries**
- [ ] All dependencies up to date (or explicitly pinned for reason)
- [ ] No deprecated dependencies
- [ ] License compliance verified
- [ ] No unused dependencies

**API integration**
- [ ] API endpoints correct
- [ ] Request/response models match API spec
- [ ] Error codes properly mapped
- [ ] Rate limiting handled
- [ ] Pagination implemented correctly

---

## 11. Documentation

**Code documentation**
- [ ] Public APIs documented
- [ ] Complex algorithms explained
- [ ] Architecture decisions documented (if new patterns introduced)
- [ ] README updated if user-facing changes
- [ ] CHANGELOG updated

**Comments quality**
- [ ] No obvious comments (code is self-explanatory)
- [ ] Why not what (explain reasoning, not mechanics)
- [ ] Complex business logic explained
- [ ] Workarounds documented with reasons

---

## 12. Git Hygiene

**Commit cleanliness**
```bash
# Review diff one more time
git diff main...HEAD

# Check commit history
git log --oneline main..HEAD
```

**Final git checks**
- [ ] No merge commits (rebase if needed)
- [ ] Logical commit groupings
- [ ] Descriptive commit messages
- [ ] No "fix typo" or "oops" commits (squash if needed)
- [ ] No unintended files committed
- [ ] No large binary files added
- [ ] .gitignore properly configured

---

## 13. PR Size Validation

**Line count check**
```bash
# Count total lines changed
git diff --stat main...HEAD | tail -1
```

**Size requirements**
- [ ] PR is < 1000 lines changed (HARD LIMIT)
- [ ] If > 1000 lines, STOP and break into smaller PRs
- [ ] Each PR is a logical, deployable unit
- [ ] PR can be reviewed in < 30 minutes

**If PR too large:**
1. STOP immediately
2. Analyze commits for logical break points
3. Create feature branch for continuation
4. Rebase/cherry-pick commits into smaller PRs
5. Submit smaller PRs sequentially

---

## 14. Final Manual Review

**Self code review**
- [ ] Read every line as if reviewing someone else's code
- [ ] Question every decision
- [ ] Look for simpler solutions
- [ ] Check for over-engineering
- [ ] Verify error messages are user-friendly
- [ ] Ensure naming is clear and consistent

**Pre-submit questions**
- Would I approve this PR if someone else wrote it?
- Is this the simplest solution that works?
- Could a junior developer understand this in 6 months?
- Does this follow team conventions?
- Would I be proud to show this to a senior engineer?

---

## Failure Protocol

If ANY check fails:

1. **DO NOT OPEN THE PR**
2. Fix the issue immediately
3. Re-run the ENTIRE checklist from the start
4. Document what was fixed

## Success Protocol

Only after ALL checks pass:

1. Generate PR description:
   - What: Brief summary of changes
   - Why: Motivation and context
   - How: Implementation approach
   - Testing: What was tested and how
   - Screenshots: If UI changes
   - Rollout: Any deployment considerations

2. Add appropriate labels

3. Assign reviewers

4. Open PR with confidence

---

## Automation Script

```bash
#!/bin/bash
# pre-pr-check.sh

set -e  # Exit on any error

echo "🔍 Starting comprehensive PR verification..."

# 1. Branch check
echo "✓ Verifying branch..."
current_branch=$(git branch --show-current)
if [ "$current_branch" = "main" ]; then
    echo "❌ Cannot submit PR from main branch"
    exit 1
fi

# 2. Clean build
echo "✓ Running clean build..."
xcodebuild clean -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
xcodebuild build -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15' -quiet || {
    echo "❌ Build failed"
    exit 1
}

# 3. SwiftLint
echo "✓ Running SwiftLint..."
swiftlint lint --strict || {
    echo "❌ SwiftLint violations found"
    swiftlint lint
    exit 1
}

# 4. Tests
echo "✓ Running test suite..."
xcodebuild test -scheme Nippardation -destination 'platform=iOS Simulator,name=iPhone 15' -quiet || {
    echo "❌ Tests failed"
    exit 1
}

# 5. Security check
echo "✓ Checking for secrets..."
if grep -rE "(API_KEY|api_key|secret|password.*=.*\"|token.*=.*\")" --include="*.swift" . ; then
    echo "❌ Potential secrets found in code"
    exit 1
fi

# 6. PR size check
lines_changed=$(git diff --stat main...HEAD | tail -1 | awk '{print $4+$6}')
if [ "$lines_changed" -gt 1000 ]; then
    echo "❌ PR too large: $lines_changed lines changed (max 1000)"
    echo "Break this into smaller PRs"
    exit 1
fi

echo "✅ All checks passed! Ready to submit PR."
```

---

## Notes

- This checklist is NON-NEGOTIABLE
- Every step must pass
- No shortcuts
- No "I'll fix it later"
- No "it's just a small change"
- Quality over speed
- The PR represents your craftsmanship

**Remember:** A PR that passes this checklist should sail through human review with minimal comments.
