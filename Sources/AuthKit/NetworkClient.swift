import Foundation

public struct HTTPRequest: Equatable, Sendable {
    public var method: String
    public var path: String
    public var body: Data?

    public init(method: String, path: String, body: Data? = nil) {
        self.method = method
        self.path = path
        self.body = body
    }
}

public enum NetworkError: Error, Equatable, Sendable {
    case offline
    case server(status: Int)
}

/// The seam that keeps tests away from the real network.
public protocol NetworkClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> (data: Data, status: Int)
}

/// Production implementation. Tests never touch it.
public struct URLSessionNetworkClient: NetworkClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> (data: Data, status: Int) {
        var urlRequest = URLRequest(url: baseURL.appending(path: request.path))
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await session.data(for: urlRequest)
            return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        }
    }
}
