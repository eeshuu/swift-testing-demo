# AuthKit: Swift Testing vs XCTest sample

Companion code for "Swift Testing vs XCTest in 2026: Migrating Real iOS Projects to Modern Testing".

- `Sources/AuthKit`: production code (validator, network client, auth service, session stores, actor repository, `@MainActor` view model)
- `Tests/AuthKitTestSupport`: mocks and fixtures shared by both test targets
- `Tests/AuthKitTests`: Swift Testing
- `Tests/AuthKitXCTests`: the same ideas in XCTest

Verified with Xcode 26.3 / Swift 6.2.4.

```bash
swift test
xcodebuild test -scheme AuthKit -destination 'platform=iOS Simulator,name=iPhone 17'
```
