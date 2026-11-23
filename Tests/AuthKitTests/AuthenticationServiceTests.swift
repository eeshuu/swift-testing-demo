import AuthKit
import AuthKitTestSupport
import Foundation
import Testing

@Suite("Authentication service", .tags(.auth, .networking))
struct AuthenticationServiceTests {
    // A fresh mock and service for every test: Swift Testing creates a new
    // instance of the suite struct per test, so init() is your setUp.
    let client = MockNetworkClient()
    let service: AuthenticationService

    init() {
        service = AuthenticationService(client: client)
    }

    @Test func successfulSignInReturnsTheSession() async throws {
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)

        let session = try await service.signIn(email: "ada@example.com", password: "correct-horse")

        #expect(session == Fixtures.session)
        let request = try #require(await client.requests.first)
        #expect(request.method == "POST")
        #expect(request.path == "auth/login")
    }

    @Test func sendsCredentialsAsJSON() async throws {
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)

        _ = try await service.signIn(email: "ada@example.com", password: "correct-horse")

        let body = try #require(await client.requests.first?.body)
        let json = try JSONDecoder().decode([String: String].self, from: body)
        #expect(json == ["email": "ada@example.com", "password": "correct-horse"])
    }

    @Test("HTTP status maps to the right error", arguments: [
        (401, AuthError.invalidCredentials),
        (500, AuthError.network(.server(status: 500))),
        (503, AuthError.network(.server(status: 503))),
    ])
    func mapsStatusCodes(status: Int, expected: AuthError) async {
        await client.stub("auth/login", status: status)

        await #expect(throws: expected) {
            try await service.signIn(email: "ada@example.com", password: "correct-horse")
        }
    }

    @Test func offlineErrorIsWrapped() async {
        await client.stub("auth/login", error: NetworkError.offline)

        await #expect(throws: AuthError.network(.offline)) {
            try await service.signIn(email: "ada@example.com", password: "correct-horse")
        }
    }

    @Test func malformedBodyIsRejected() async {
        await client.stub("auth/login", status: 200, json: #"{"token": 42}"#)

        await #expect(throws: AuthError.malformedResponse) {
            try await service.signIn(email: "ada@example.com", password: "correct-horse")
        }
    }

    @Test func invalidInputNeverHitsTheNetwork() async {
        await #expect(throws: AuthError.validation(.invalidEmail)) {
            try await service.signIn(email: "ada", password: "correct-horse")
        }
        #expect(await client.requests.isEmpty)
    }
}
