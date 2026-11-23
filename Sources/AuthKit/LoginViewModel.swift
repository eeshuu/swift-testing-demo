import Observation

@MainActor
@Observable
public final class LoginViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case signedIn(User)
        case failed(message: String)
    }

    public var email = ""
    public var password = ""
    public private(set) var state: State = .idle

    /// Called once after a successful sign-in, e.g. to switch to the home screen.
    public var onSignedIn: ((User) -> Void)?

    private let repository: UserRepository
    private let validator: CredentialValidator

    public init(repository: UserRepository, validator: CredentialValidator = CredentialValidator()) {
        self.repository = repository
        self.validator = validator
    }

    public var canSubmit: Bool {
        state != .loading
            && validator.isValidEmail(email)
            && password.count >= validator.minimumPasswordLength
    }

    public func signIn() async {
        guard state != .loading else { return }
        state = .loading
        do {
            let user = try await repository.signIn(email: email, password: password)
            state = .signedIn(user)
            onSignedIn?(user)
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    static func message(for error: any Error) -> String {
        switch error as? AuthError {
        case .invalidCredentials: "Email or password is incorrect."
        case .network(.offline): "You're offline. Check your connection and try again."
        case .validation(.invalidEmail), .validation(.emptyEmail): "Enter a valid email address."
        case .validation(.passwordTooShort(let minimum)): "Password must be at least \(minimum) characters."
        default: "Something went wrong. Please try again."
        }
    }
}
