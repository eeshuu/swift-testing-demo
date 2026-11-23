import AuthKit
import AuthKitTestSupport
import Testing

@MainActor
@Suite("Login view model", .tags(.auth))
struct LoginViewModelTests {
    let client = MockNetworkClient()
    let viewModel: LoginViewModel

    init() {
        let repository = UserRepository(
            auth: AuthenticationService(client: client),
            store: InMemorySessionStore()
        )
        viewModel = LoginViewModel(repository: repository)
    }

    @Test func submitIsDisabledUntilTheFormIsValid() {
        #expect(!viewModel.canSubmit)
        viewModel.email = "ada@example.com"
        #expect(!viewModel.canSubmit)
        viewModel.password = "correct-horse"
        #expect(viewModel.canSubmit)
    }

    @Test func successfulSignInNotifiesOnce() async {
        await client.stub("auth/login", status: 200, json: Fixtures.sessionJSON)
        viewModel.email = "ada@example.com"
        viewModel.password = "correct-horse"

        await confirmation("onSignedIn is called") { signedIn in
            viewModel.onSignedIn = { user in
                #expect(user == Fixtures.user)
                signedIn()
            }
            await viewModel.signIn()
        }
        #expect(viewModel.state == .signedIn(Fixtures.user))
    }

    @Test func failedSignInNeverNotifies() async {
        await client.stub("auth/login", status: 401)
        viewModel.email = "ada@example.com"
        viewModel.password = "wrong-password"

        await confirmation("onSignedIn is not called", expectedCount: 0) { signedIn in
            viewModel.onSignedIn = { _ in signedIn() }
            await viewModel.signIn()
        }
        #expect(viewModel.state == .failed(message: "Email or password is incorrect."))
    }

    @Test("Shows a readable message for each failure", arguments: [
        (AuthError.network(.offline), "You're offline. Check your connection and try again."),
        (AuthError.validation(.passwordTooShort(minimum: 8)), "Password must be at least 8 characters."),
        (AuthError.malformedResponse, "Something went wrong. Please try again."),
    ])
    func errorMessages(error: AuthError, message: String) async {
        let repository = UserRepository(auth: FailingAuth(error: error), store: InMemorySessionStore())
        let viewModel = LoginViewModel(repository: repository)

        await viewModel.signIn()

        #expect(viewModel.state == .failed(message: message))
    }
}

/// A tiny protocol-based stub: no network, no JSON.
private struct FailingAuth: Authenticating {
    let error: AuthError
    func signIn(email: String, password: String) async throws -> Session { throw error }
}
