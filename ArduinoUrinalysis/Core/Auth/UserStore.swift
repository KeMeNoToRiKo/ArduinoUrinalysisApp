//
//  UserStore.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/24/26.
//
import Foundation
import SwiftData
import CryptoKit

@Model
public final class UserEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var email: String
    @Attribute public var username: String
    public var name: String?
    public var passwordHash: String
    
    public init(
        id: UUID = UUID(),
        email: String,
        username: String,
        name: String? = nil,
        passwordHash: String
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.name = name
        self.passwordHash = passwordHash
    }
}

public enum UserStoreError: Error {
    case emailAlreadyExists
    case usernameAlreadyExists
    case userNotFound
    case invalidPassword
    case storageError
}

public final class UserStore {
    
    // FOR LOOKUP
    public static func findUser (
        byEmail email: String,
        in context: ModelContext
    ) -> UserEntity? {
        let lower = email.lowercased()
        let descriptor = FetchDescriptor<UserEntity>()
        guard let list = try? context.fetch(descriptor) else {
            return nil
        }
        return list.first(where: { $0.email.lowercased() == lower })
    }
    
    public static func findUser (
        byUsername username: String,
        in context: ModelContext
    ) -> UserEntity? {
        _ = username.lowercased()
        let descriptor = FetchDescriptor<UserEntity>()
        guard let list = try? context.fetch(descriptor) else {
            return nil
        }
        return list.first(where: { $0.username == username })
    }
    
    // FINDS USER BY EITHER EMAIL OR uSERNAME
    public static func findUser (
        byEmailOrUsername identifier: String,
        in context: ModelContext
    ) -> UserEntity? {
        if identifier.contains("@") {
            return findUser(byEmail: identifier, in: context)
        } else {
            return findUser(byUsername: identifier, in: context)
        }
    }
    
    
    
    // WRITE USER
    public static func addUser(
        email: String,
        username: String,
        password: String,
        in context: ModelContext
    ) throws -> UserEntity {
        if findUser(byEmail: email, in: context) != nil {
            throw UserStoreError.emailAlreadyExists
        }
        if findUser(byUsername: username, in: context) != nil {
            throw UserStoreError.usernameAlreadyExists
        }
        
        let user = UserEntity(
            email: email,
            username: username,
            passwordHash: hashPassword(password)
        )
        context.insert(user)
        do {
            try context.save()
        } catch {
            throw UserStoreError.storageError
        }
        return user
    }
    
    // AUTH
    public static func verify(
        identifier: String,
        password: String,
        in context: ModelContext
    ) -> Bool {
        guard let user = findUser(byEmailOrUsername: identifier, in: context) else { return false }
        return user.passwordHash == hashPassword(password)
    }
    
    //HELPERS
    public static func allUsers(in context: ModelContext) -> [UserEntity] {
            let descriptor = FetchDescriptor<UserEntity>()
            return (try? context.fetch(descriptor)) ?? []
        }
     
        private static func hashPassword(_ password: String) -> String {
            let data = Data(password.utf8)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }
    
}
