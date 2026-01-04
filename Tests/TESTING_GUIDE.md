# Testing Guide for atvfin

This document provides guidance on writing and running tests for the atvfin project.

## Test Structure

Tests are organized in the `Tests/` directory with the following structure:

```
Tests/
├── SharedTests/        # Tests for shared business logic
│   ├── DownloadTaskTests.swift
│   └── ...
└── UITests/           # UI tests for tvOS app
    └── ...
```

## Running Tests

### Via Xcode
1. Open `Swiftfin.xcodeproj` (Note: Update to actual project file name)
2. Select the test scheme
3. Press `Cmd+U` to run all tests
4. Press `Cmd+Control+Option+U` to run tests with code coverage

### Via Command Line
```bash
# Run all tests (update scheme name to match your project)
xcodebuild test -scheme "Swiftfin tvOS" -destination "platform=tvOS Simulator,name=Apple TV 4K"

# Run specific test class
xcodebuild test -scheme "Swiftfin tvOS" -only-testing:SharedTests/DownloadTaskTests

# Run with code coverage
xcodebuild test -scheme "Swiftfin tvOS" -enableCodeCoverage YES
```

## Writing Tests

### Test Naming Convention

Follow the Given-When-Then pattern in test names:

```swift
func test<MethodName>_<Condition>_Should<ExpectedResult>() {
    // Given: Setup test conditions
    
    // When: Execute the code being tested
    
    // Then: Assert expected results
}
```

Examples:
- `testDownloadTask_WithValidItem_ShouldInitialize()`
- `testEncodeMetadata_WithMissingData_ShouldThrowError()`
- `testCancel_WhenDownloading_ShouldSetStateToCancelled()`

### Test Organization

Organize tests using `// MARK:` comments:

```swift
final class MyTests: XCTestCase {
    // MARK: - Properties
    
    // MARK: - Setup & Teardown
    
    // MARK: - Initialization Tests
    
    // MARK: - Business Logic Tests
    
    // MARK: - Error Handling Tests
    
    // MARK: - Helper Methods
}
```

### Best Practices

1. **Use setUp() and tearDown()**
   ```swift
   override func setUpWithError() throws {
       try super.setUpWithError()
       sut = SystemUnderTest()
   }
   
   override func tearDownWithError() throws {
       sut = nil
       try super.tearDownWithError()
   }
   ```

2. **Test one thing per test**
   - Each test should verify a single behavior
   - If you need multiple assertions, they should all relate to the same behavior

3. **Use descriptive assertions**
   ```swift
   // Good
   XCTAssertEqual(result, expected, "User authentication should succeed with valid credentials")
   
   // Less helpful
   XCTAssertEqual(result, expected)
   ```

4. **Test error conditions**
   ```swift
   func testMethod_WithInvalidInput_ShouldThrowError() async throws {
       do {
           try await methodUnderTest()
           XCTFail("Expected error to be thrown")
       } catch let error as CustomError {
           XCTAssertEqual(error, .expectedError)
       }
   }
   ```

5. **Use mocks for dependencies**
   ```swift
   protocol NetworkClientProtocol {
       func fetch() async throws -> Data
   }
   
   class MockNetworkClient: NetworkClientProtocol {
       var shouldFail = false
       
       func fetch() async throws -> Data {
           if shouldFail {
               throw NetworkError.connectionFailed
           }
           return Data()
       }
   }
   ```

## Test Coverage Goals

- **Critical paths**: 80%+ coverage
  - Authentication
  - Download management
  - Video playback
  - Error handling

- **UI code**: 50%+ coverage
  - User flows
  - Navigation
  - State management

- **Utilities**: 70%+ coverage

## Async Testing

For async code, use Swift's async/await in tests:

```swift
func testAsyncMethod() async throws {
    // Given
    let expected = "result"
    
    // When
    let actual = try await methodUnderTest()
    
    // Then
    XCTAssertEqual(actual, expected)
}
```

## UI Testing

For tvOS UI tests, focus on:
- Focus navigation
- User interactions
- View transitions
- Accessibility

Example:
```swift
func testNavigationFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate using focus
    let remote = XCUIRemote.shared
    remote.press(.down)
    remote.press(.select)
    
    // Verify navigation
    XCTAssertTrue(app.staticTexts["Expected Title"].exists)
}
```

## Test Data

- Store test fixtures in `Tests/TestData/`
- Use JSON files for complex test data
- Create builders for test objects:

```swift
class BaseItemDtoBuilder {
    private var item = BaseItemDto()
    
    func withID(_ id: String) -> Self {
        item.id = id
        return self
    }
    
    func build() -> BaseItemDto {
        return item
    }
}

// Usage:
let testItem = BaseItemDtoBuilder()
    .withID("123")
    .withTitle("Test Movie")
    .build()
```

## Continuous Integration

Tests run automatically on:
- Pull requests
- Pushes to main branch

CI configuration is in `.github/workflows/ci.yml`

## Troubleshooting

### Tests Failing on CI but Passing Locally
- Check Xcode version matches CI
- Ensure deterministic test behavior (no time-dependent tests)
- Check for race conditions in async tests

### Flaky Tests
- Add explicit waits for async operations
- Use `XCTExpectation` for asynchronous testing
- Avoid hardcoded delays; use expectations instead

## Resources

- [Apple Testing Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://www.swift.org/blog/testing/)
- [tvOS Testing Guide](https://developer.apple.com/tvos/testing/)
