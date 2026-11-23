import AuthKit
import AuthKitTestSupport
import Testing

@Suite("File session store", .tags(.persistence), .temporaryDirectory)
struct FileSessionStoreTests {
    let store: FileSessionStore

    init() throws {
        let directory = try #require(TemporaryDirectoryTrait.current)
        store = FileSessionStore(directory: directory)
    }

    @Test func emptyStoreLoadsNil() async throws {
        #expect(try await store.load() == nil)
    }

    @Test func savedSessionRoundTrips() async throws {
        try await store.save(Fixtures.session)
        #expect(try await store.load() == Fixtures.session)
    }

    @Test func clearRemovesTheSession() async throws {
        try await store.save(Fixtures.session)
        try await store.clear()
        #expect(try await store.load() == nil)
    }
}
