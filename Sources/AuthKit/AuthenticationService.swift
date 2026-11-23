import Foundation

public struct User: Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String

    public init(id: String, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}

public struct Session: Codable, Equatable, Sendable {
    public let token: String
    public let user: User

    public init(token: String, user: User) {
        self.token = token
        self.user = user
    }
}

public enum AuthError: Error, Equatable, Sendable {
    case validation(ValidationError)
    case invalidCredentials
    case network(NetworkError)
    case malformedResponse
}

public protocol Authenticating: Sendable {
    func signIn(email: String, password: String) async throws -> Session
}

public struct AuthenticationService: Authenticating {
    private let client: any NetworkClient
    private let validator: CredentialValidator

    public init(client: any NetworkClient, validator: CredentialValidator = CredentialValidator()) {
        self.client = client
        self.validator = validator
    }

    public func signIn(email: String, password: String) async throws -> Session {
        do {
            try validator.validate(email: email, password: password)
        } catch {
            throw AuthError.validation(error)
        }

        let body = try JSONEncoder().encode(["email": email, "password": password])
        let response: (data: Data, status: Int)
        do {
            response = try await client.send(HTTPRequest(method: "POST", path: "auth/login", body: body))
        } catch let error as NetworkError {
            throw AuthError.network(error)
        }

        switch response.status {
        case 200:
            guard let session = try? JSONDecoder().decode(Session.self, from: response.data) else {
                throw AuthError.malformedResponse
            }
            return session
        case 401:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.network(.server(status: response.status))
        }
    }
}
