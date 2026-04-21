//
//  AuthErrors.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

import Foundation

public enum AuthError: LocalizedError {
    // Login
    case emptyIdentifier
    case emptyPassword
    case invalidCredentials
    // Register
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
        case .emptyIdentifier:           return "Please enter your email or username."
        case .emptyPassword:             return "Please enter your password."
        case .invalidCredentials:        return "Incorrect email/username or password."
        case .invalidEmail:              return "Please enter a valid email address."
        case .usernameTooShort:          return "Username must be at least 3 characters."
        case .usernameInvalidCharacters: return "Username may only contain letters, numbers, underscores, and hyphens."
        case .passwordTooShort:          return "Password must be at least 6 characters."
        case .passwordsDoNotMatch:       return "Passwords do not match."
        case .emailAlreadyExists:        return "An account with this email already exists."
        case .usernameAlreadyExists:     return "This username is already taken."
        case .storageError:              return "Something went wrong saving your account. Please try again."
        }
    }
}
