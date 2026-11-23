/// Owns the signed-in user. An actor, because the UI, background refresh
/// and deep links can all reach it at the same time.
public actor UserRepository {
    private let auth: any Authenticating
    private let store: any SessionStore
    private var inFlight: Task<Session, any Error>?

    public private(set) var currentUser: User?

    public init(auth: any Authenticating, store: any SessionStore) {
        self.auth = auth
        self.store = store
    }

    /// A second tap on "Sign in" while a request is running joins that request
    /// instead of sending another one.
    public func signIn(email: String, password: String) async throws -> User {
        if let inFlight {
            return try await inFlight.value.user
        }
        let task = Task { [auth] in try await auth.signIn(email: email, password: password) }
        inFlight = task
        defer { inFlight = nil }

        let session = try await task.value
        try await store.save(session)
        currentUser = session.user
        return session.user
    }

    public func restore() async throws -> User? {
        currentUser = try await store.load()?.user
        return currentUser
    }

    public func signOut() async throws {
        try await store.clear()
        currentUser = nil
    }
}
