import Foundation
import Testing

extension Tag {
    @Tag static var auth: Self
    @Tag static var networking: Self
    @Tag static var persistence: Self
}

/// A custom trait (Swift 6.1+) that gives each test its own empty directory
/// and deletes it afterwards: setUp/tearDown, packaged as a reusable trait.
struct TemporaryDirectoryTrait: TestTrait, SuiteTrait, TestScoping {
    @TaskLocal static var current: URL?

    // On a suite, apply the scope to every test inside it, not once for the whole suite.
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // Suites call this too; only tests need a directory.
        guard !test.isSuite else { return try await function() }
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "AuthKitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await Self.$current.withValue(directory) {
            try await function()
        }
    }
}

extension Trait where Self == TemporaryDirectoryTrait {
    static var temporaryDirectory: Self { Self() }
}
