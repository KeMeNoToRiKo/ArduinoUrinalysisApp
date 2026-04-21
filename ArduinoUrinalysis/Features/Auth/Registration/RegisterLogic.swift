//
//  RegisterLogic.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/24/26.
//
//
//  RegisterLogic.swift
//  ArduinoUrinalysis
//

import Foundation
import SwiftData

public enum RegisterError: LocalizedError {
    case invalidEmail
    case usernameTooShort
    case usernameInvalidCharacters
    case passwordTooShort
    case passwordsDoNotMatch
    case emailAlreadyExists
    case usernameAlreadyExists
    case storageError

    public var errorDescription: String? {
        switch self {
        case .invalidEmail:              return "Please enter a valid email address."
        case .usernameTooShort:         return "Username must be at least 3 characters."
        case .usernameInvalidCharacters: return "Username may only contain letters, numbers, underscores, and hyphens."
        case .passwordTooShort:         return "Password must be at least 6 characters."
        case .passwordsDoNotMatch:      return "Passwords do not match."
        case .emailAlreadyExists:       return "An account with this email already exists."
        case .usernameAlreadyExists:    return "This username is already taken."
        case .storageError:             return "Something went wrong saving your account. Please try again."
        }
    }
}

public final class RegisterLogic {
    public init() {}

    /// Validates all fields, then persists the new user. Throws a descriptive `RegisterError` on failure.
    public func register(
        email: String,
        username: String,
        password: String,
        confirmPassword: String,
        in context: ModelContext
    ) throws -> UserEntity {
        let trimmedEmail    = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedEmail)       else { throw RegisterError.invalidEmail }
        guard trimmedUsername.count >= 3       else { throw RegisterError.usernameTooShort }
        guard isValidUsername(trimmedUsername) else { throw RegisterError.usernameInvalidCharacters }
        guard password.count >= 6              else { throw RegisterError.passwordTooShort }
        guard password == confirmPassword      else { throw RegisterError.passwordsDoNotMatch }

        do {
            return try UserStore.addUser(
                email: trimmedEmail,
                username: trimmedUsername,
                password: password,
                in: context
            )
        } catch UserStoreError.emailAlreadyExists {
            throw RegisterError.emailAlreadyExists
        } catch UserStoreError.usernameAlreadyExists {
            throw RegisterError.usernameAlreadyExists
        } catch {
            throw RegisterError.storageError
        }
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
