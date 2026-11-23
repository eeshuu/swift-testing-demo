import AuthKit
import AuthKitTestSupport
import XCTest

final class AuthenticationServiceXCTests: XCTestCase {
    private var client: MockNetworkClient!
    private var service: AuthenticationService!

    override func setUp() async throws {
        try await super.setUp()
        client = MockNetworkClient()
        service = AuthenticationService(client: client)
    }

    override func tearDown() async throws {
        client = nil
        service = nil
        try await super.tearDown()
    }

    func testSuccessfulSignInReturnsTheSession() async throws {
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)

        let session = try await service.signIn(email: "ada@example.com", password: "correct-horse")

        XCTAssertEqual(session, Fixtures.session)
        let requests = await client.requests
        XCTAssertEqual(requests.count, 1)
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.path, "auth/login")
    }

    func testWrongPasswordThrowsInvalidCredentials() async {
        await client.stub("auth/login", status: 401)

        // XCTAssertThrowsError can't take an async expression, so use do/catch.
        do {
            _ = try await service.signIn(email: "ada@example.com", password: "wrong-password")
            XCTFail("Expected signIn to throw")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCredentials)
        }
    }

    func testServerErrorsAreMapped() async {
        for status in [500, 503] {
            await client.stub("auth/login", status: status)
            do {
                _ = try await service.signIn(email: "ada@example.com", password: "correct-horse")
                XCTFail("Expected an error for status \(status)")
            } catch {
                XCTAssertEqual(error as? AuthError, .network(.server(status: status)), "status \(status)")
            }
        }
    }

    func testValidatorRejectsShortPassword() {
        let validator = CredentialValidator()
        XCTAssertTrue(validator.isValidEmail("ada@example.com"))
        XCTAssertThrowsError(try validator.validate(email: "ada@example.com", password: "123")) { error in
            XCTAssertEqual(error as? ValidationError, .passwordTooShort(minimum: 8))
        }
    }
}

@MainActor
final class LoginViewModelXCTests: XCTestCase {
    func testSuccessfulSignInCallsOnSignedIn() async {
        let client = MockNetworkClient()
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)
        let viewModel = LoginViewModel(
            repository: UserRepository(auth: AuthenticationService(client: client), store: InMemorySessionStore())
        )
        viewModel.email = "ada@example.com"
        viewModel.password = "correct-horse"

        let signedIn = expectation(description: "onSignedIn is called")
        viewModel.onSignedIn = { _ in signedIn.fulfill() }

        await viewModel.signIn()

        await fulfillment(of: [signedIn], timeout: 1)
        XCTAssertEqual(viewModel.state, .signedIn(Fixtures.user))
    }
}
