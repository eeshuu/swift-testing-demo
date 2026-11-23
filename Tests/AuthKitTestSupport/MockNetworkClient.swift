import AuthKit
import Foundation

/// An actor, so tests running in parallel can't race on `requests`.
public actor MockNetworkClient: NetworkClient {
    private var responses: [String: Result<(data: Data, status: Int), any Error>] = [:]
    public private(set) var requests: [HTTPRequest] = []
    private let delay: Duration

    public init(delay: Duration = .zero) {
        self.delay = delay
    }

    public func stub(_ path: String, status: Int, json: String = "{}") {
        responses[path] = .success((Data(json.utf8), status))
    }

    public func stub(_ path: String, error: any Error) {
        responses[path] = .failure(error)
    }

    public func send(_ request: HTTPRequest) async throws -> (data: Data, status: Int) {
        requests.append(request)
        if delay > .zero { try await Task.sleep(for: delay) }
        guard let response = responses[request.path] else {
            throw NetworkError.server(status: 404)
        }
        return try response.get()
    }
}

public enum Fixtures {
    public static let user = User(id: "u_1", email: "ada@example.com", displayName: "Ada")
    public static let session = Session(token: "token-123", user: user)
    public static let sessionJSON = """
    {"token":"token-123","user":{"id":"u_1","email":"ada@example.com","displayName":"Ada"}}
    """
}
