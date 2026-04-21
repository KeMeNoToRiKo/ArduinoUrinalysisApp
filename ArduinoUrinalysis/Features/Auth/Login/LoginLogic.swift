//
//  LoginLogic.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/12/26.
//

import Foundation
import SwiftData
 
public enum LoginError: LocalizedError {
    case emptyIdentifier
    case emptyPassword
    case invalidCredentials
 
    public var errorDescription: String? {
        switch self {
        case .emptyIdentifier:    return "Please enter your email or username."
        case .emptyPassword:      return "Please enter your password."
        case .invalidCredentials: return "Incorrect email/username or password."
        }
    }
}
 
public final class LoginLogic {
    public init() {}
 
    /// Validates input and verifies credentials.
    /// The identifier is auto-detected as email (contains "@") or username.
    /// Returns the authenticated `UserEntity` on success, or throws `LoginError`.
    @discardableResult
    public func login(
        identifier: String,
        password: String,
        in context: ModelContext
    ) throws -> UserEntity {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
 
        guard !trimmed.isEmpty    else { throw LoginError.emptyIdentifier }
        guard !password.isEmpty   else { throw LoginError.emptyPassword }
 
        guard UserStore.verify(identifier: trimmed, password: password, in: context) else {
            throw LoginError.invalidCredentials
        }
 
        // Safe to force-unwrap: verify() already confirmed the user exists.
        return UserStore.findUser(byEmailOrUsername: trimmed, in: context)!
    }
 
    /// Convenience helper so the UI can show a contextual placeholder.
    public static func identifierType(for input: String) -> IdentifierType {
        input.contains("@") ? .email : .username
    }
 
    public enum IdentifierType {
        case email, username
    }
}
 
