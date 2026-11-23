import AuthKit
import AuthKitTestSupport
import Testing

@Suite("User repository", .tags(.auth))
struct UserRepositoryTests {
    @Test func signInStoresTheSession() async throws {
        let client = MockNetworkClient()
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)
        let store = InMemorySessionStore()
        let repository = UserRepository(auth: AuthenticationService(client: client), store: store)

        let user = try await repository.signIn(email: "ada@example.com", password: "correct-horse")

        #expect(user == Fixtures.user)
        #expect(await repository.currentUser == Fixtures.user)
        #expect(try await store.load() == Fixtures.session)
    }

    @Test(.timeLimit(.minutes(1)))
    func concurrentSignInsShareOneRequest() async throws {
        // The delay keeps the first request in flight while the others arrive.
        let client = MockNetworkClient(delay: .milliseconds(200))
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)
        let repository = UserRepository(auth: AuthenticationService(client: client), store: InMemorySessionStore())

        let users = try await withThrowingTaskGroup(of: User.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await repository.signIn(email: "ada@example.com", password: "correct-horse")
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(users.count == 5)
        #expect(users.allSatisfy { $0 == Fixtures.user })
        #expect(await client.requests.count == 1)
    }

    @Test func failedSignInLeavesNoUser() async {
        let client = MockNetworkClient()
        await client.stub("auth/login", status: 401)
        let repository = UserRepository(auth: AuthenticationService(client: client), store: InMemorySessionStore())

        await #expect(throws: AuthError.invalidCredentials) {
            try await repository.signIn(email: "ada@example.com", password: "wrong-password")
        }
        #expect(await repository.currentUser == nil)
    }

    @Test func signOutClearsEverything() async throws {
        let store = InMemorySessionStore(session: Fixtures.session)
        let repository = UserRepository(auth: AuthenticationService(client: MockNetworkClient()), store: store)
        #expect(try await repository.restore() == Fixtures.user)

        try await repository.signOut()

        #expect(await repository.currentUser == nil)
        #expect(try await store.load() == nil)
    }
}
