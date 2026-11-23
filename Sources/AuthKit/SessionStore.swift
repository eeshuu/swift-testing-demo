import Foundation

public protocol SessionStore: Sendable {
    func save(_ session: Session) async throws
    func load() async throws -> Session?
    func clear() async throws
}

/// Persists the session as JSON in a directory the caller chooses.
public actor FileSessionStore: SessionStore {
    private let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appending(path: "session.json")
    }

    public func save(_ session: Session) throws {
        try JSONEncoder().encode(session).write(to: fileURL, options: .atomic)
    }

    public func load() throws -> Session? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try JSONDecoder().decode(Session.self, from: Data(contentsOf: fileURL))
    }

    public func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

public actor InMemorySessionStore: SessionStore {
    private var session: Session?

    public init(session: Session? = nil) {
        self.session = session
    }

    public func save(_ session: Session) { self.session = session }
    public func load() -> Session? { session }
    public func clear() { session = nil }
}
