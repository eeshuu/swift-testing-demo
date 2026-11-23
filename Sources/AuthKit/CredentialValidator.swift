import Foundation
public enum ValidationError: Error, Equatable, Sendable {
    case emptyEmail
    case invalidEmail
    case passwordTooShort(minimum: Int)
}

/// Pure value type: no I/O, no shared state. The easiest thing to test.
public struct CredentialValidator: Sendable {
    public let minimumPasswordLength: Int

    public init(minimumPasswordLength: Int = 8) {
        self.minimumPasswordLength = minimumPasswordLength
    }

    public func validate(email: String, password: String) throws(ValidationError) {
        let email = email.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { throw .emptyEmail }
        guard isValidEmail(email) else { throw .invalidEmail }
        guard password.count >= minimumPasswordLength else {
            throw .passwordTooShort(minimum: minimumPasswordLength)
        }
    }

    /// Deliberately simple: one "@", a non-empty name, and a dotted domain.
    public func isValidEmail(_ email: String) -> Bool {
        let parts = email.trimmingCharacters(in: .whitespaces).split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[0].contains(" ") else { return false }
        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".") && !domain.contains(" ")
    }
}
