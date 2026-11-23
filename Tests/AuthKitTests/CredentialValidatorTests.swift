import AuthKit
import Testing

@Suite("Credential validation", .tags(.auth))
struct CredentialValidatorTests {
    let validator = CredentialValidator(minimumPasswordLength: 8)

    @Test("Accepts well-formed emails", arguments: [
        "ada@example.com",
        "first.last@company.co.uk",
        "  padded@example.com  ",
    ])
    func acceptsValidEmail(_ email: String) {
        #expect(validator.isValidEmail(email))
    }

    @Test("Rejects malformed emails", arguments: [
        "", "ada", "ada@", "@example.com", "ada@example", "ada@.com", "ada@example.", "a da@example.com",
    ])
    func rejectsInvalidEmail(_ email: String) {
        #expect(!validator.isValidEmail(email))
    }

    @Test("Maps each bad input to the right error", arguments: zip(
        ["", "not-an-email", "ada@example.com"],
        [ValidationError.emptyEmail, .invalidEmail, .passwordTooShort(minimum: 8)]
    ))
    func reportsTheRightError(email: String, expected: ValidationError) {
        #expect(throws: expected) {
            try validator.validate(email: email, password: "short")
        }
    }

    @Test func passwordAtMinimumLengthIsAccepted() {
        #expect(throws: Never.self) {
            try validator.validate(email: "ada@example.com", password: "12345678")
        }
    }

    @Test func thrownErrorCanBeInspected() throws {
        // Swift 6.1+: #expect(throws:) returns the error it caught
        let error = #expect(throws: ValidationError.self) {
            try validator.validate(email: "ada@example.com", password: "123")
        }
        #expect(error == .passwordTooShort(minimum: 8))
    }
}
