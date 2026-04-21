//
//  AuthLogic.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

import Foundation
import SwiftData

// MARK: - AuthLogic

public final class AuthLogic {
    public init() {}

    // MARK: Login

    /// Validates input and verifies credentials against the store.
    /// Returns the authenticated `UserEntity` on success, or throws `AuthError`.
    @discardableResult
    public func login(
        identifier: String,
        password: String,
        in context: ModelContext
    ) throws -> UserEntity {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty  else { throw AuthError.emptyIdentifier }
        guard !password.isEmpty else { throw AuthError.emptyPassword }

        guard UserStore.verify(identifier: trimmed, password: password, in: context) else {
            throw AuthError.invalidCredentials
        }

        // Safe force-unwrap: verify() already confirmed the user exists.
        return UserStore.findUser(byEmailOrUsername: trimmed, in: context)!
    }

    // MARK: Register

    /// Validates all fields, then persists the new user.
    /// Returns the created `UserEntity` on success, or throws `AuthError`.
    @discardableResult
    public func register(
        email: String,
        username: String,
        password: String,
        confirmPassword: String,
        in context: ModelContext
    ) throws -> UserEntity {
        let trimmedEmail    = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedEmail)        else { throw AuthError.invalidEmail }
        guard trimmedUsername.count >= 3        else { throw AuthError.usernameTooShort }
        guard isValidUsername(trimmedUsername)  else { throw AuthError.usernameInvalidCharacters }
        guard password.count >= 6              else { throw AuthError.passwordTooShort }
        guard password == confirmPassword      else { throw AuthError.passwordsDoNotMatch }

        do {
            return try UserStore.addUser(
                email: trimmedEmail,
                username: trimmedUsername,
                password: password,
                in: context
            )
        } catch UserStoreError.emailAlreadyExists {
            throw AuthError.emailAlreadyExists
        } catch UserStoreError.usernameAlreadyExists {
            throw AuthError.usernameAlreadyExists
        } catch {
            throw AuthError.storageError
        }
    }

    // MARK: - Helpers

    /// Infers whether the identifier field contains an email or a username.
    public static func identifierType(for input: String) -> IdentifierType {
        input.contains("@") ? .email : .username
    }

    public enum IdentifierType {
        case email, username
    }

    // MARK: - Private Validators

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    /// Allows letters, digits, underscores, and hyphens.
    private func isValidUsername(_ username: String) -> Bool {
        let pattern = #"^[A-Za-z0-9_\-]+$"#
        return username.range(of: pattern, options: .regularExpression) != nil
    }
}
