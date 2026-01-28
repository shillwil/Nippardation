# iOS Testing Skill

## Purpose
Ensure comprehensive test coverage for all code changes before committing. This skill identifies what changed on the current branch, determines necessary test coverage, implements or updates tests, and verifies they pass.

## Core Responsibilities

### 1. Identify Changes
```bash
# Get list of changed files on current branch
git diff --name-only $(git merge-base HEAD main)..HEAD

# Get detailed diff for analysis
git diff $(git merge-base HEAD main)..HEAD
```

### 2. Analyze Test Requirements

For each changed file, determine required test coverage:

**ViewModels/Business Logic**
- Unit tests for all public methods
- Test all code paths and branches
- Edge cases and error conditions
- Mock dependencies appropriately
- Verify state changes
- Test async/await operations
- Test Combine publishers if applicable

**Models/Data Structures**
- Codable encode/decode tests
- Equatable/Hashable verification
- Validation logic tests
- Default value tests

**Network/Repository Layer**
- Mock API response tests
- Error handling tests
- Data mapping tests
- Cache behavior tests
- Retry logic tests

**Database/Persistence**
- CRUD operation tests
- Migration tests
- Query correctness tests
- Data integrity tests

### 3. Test Implementation Standards

**Naming Convention**
```swift
func test_methodName_condition_expectedOutcome() {
    // Arrange
    // Act
    // Assert
}
```

**Structure Requirements**
- Use Arrange-Act-Assert pattern
- One logical assertion per test
- Clear test names describing scenario
- Isolated tests (no interdependencies)
- Fast execution (mock slow operations)

**Coverage Targets**
- Critical business logic: 100%
- ViewModels: 90%+
- Repositories/Services: 85%+
- Models/Utilities: 80%+

### 4. Test Execution Verification

```bash
# Run full unit test suite
xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:YourTargetTests

# Run specific test class during development
xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:YourTargetTests/TestClassName

# Check test coverage
xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES -only-testing:YourTargetTests
```

### 5. Quality Gates

Before allowing commit:
- [ ] All new code has corresponding tests
- [ ] All tests pass
- [ ] No skipped tests without documented reason
- [ ] Test coverage meets minimum thresholds
- [ ] No force-unwraps in test code without explicit nil checks
- [ ] Async tests properly use expectations or async/await
- [ ] Mock objects are properly configured
- [ ] Tests are deterministic (no random failures)

### 6. Special Considerations

**Combine Testing**
- Use TestScheduler for time-based operations
- Verify publisher sequences
- Test cancellation behavior
- Verify error handling

**Async/Await Testing**
```swift
func testAsyncOperation() async throws {
    let result = await sut.fetchData()
    XCTAssertEqual(result.count, expectedCount)
}
```

**Performance Testing**
```swift
func testPerformance() {
    measure {
        // Code to measure
    }
}
```

### 7. Test Organization

```
Tests/
├── UnitTests/
│   ├── ViewModels/
│   ├── Services/
│   ├── Models/
│   └── Utilities/
└── IntegrationTests/
    ├── Network/
    ├── Database/
    └── API/
```

### 8. Execution Workflow

1. **Detect changes**: `git diff` to identify modified files
2. **Analyze**: Determine what tests are needed based on changes
3. **Implement**: Write or update tests following standards
4. **Verify**: Run tests and confirm they pass
5. **Check coverage**: Ensure coverage thresholds are met
6. **Report**: Summarize test additions/updates made
7. **Block if failing**: Do not proceed to commit if any tests fail

### 9. Common Patterns

**Testing Network Responses**
```swift
func test_fetchData_validResponse_returnsData() async throws {
    // Arrange
    let mockData = MockData.valid
    mockNetworkService.stubbedResult = .success(mockData)
    
    // Act
    let result = await sut.fetchData()
    
    // Assert
    XCTAssertEqual(result, expectedData)
}
```

**Testing Error Handling**
```swift
func test_fetchData_networkError_throwsError() async {
    // Arrange
    mockNetworkService.stubbedResult = .failure(.networkError)
    
    // Act & Assert
    await XCTAssertThrowsError(await sut.fetchData())
}
```

**Testing State Changes**
```swift
func test_buttonTap_updatesState() {
    // Arrange
    let viewModel = ViewModel()
    XCTAssertFalse(viewModel.isLoading)
    
    // Act
    viewModel.handleButtonTap()
    
    // Assert
    XCTAssertTrue(viewModel.isLoading)
}
```

### 10. Exclusions

Do not require tests for:
- Generated code (e.g., Core Data models)
- Simple data structures with no logic
- Third-party code
- Temporary debugging code
- Prototype/experimental features explicitly marked as such

### 11. Failure Response

If tests fail after implementation:
1. Review test logic for correctness
2. Check if production code has bugs
3. Verify mocks are configured correctly
4. Check for race conditions in async tests
5. Ensure tests are isolated (no shared state)
6. Fix issues before proceeding to commit

## Success Criteria

- All changed code has appropriate unit test coverage
- All unit tests pass consistently
- Unit test suite runs in reasonable time (<3 minutes)
- Tests are maintainable and well-organized
- Coverage meets or exceeds project thresholds
- No flaky tests introduced
