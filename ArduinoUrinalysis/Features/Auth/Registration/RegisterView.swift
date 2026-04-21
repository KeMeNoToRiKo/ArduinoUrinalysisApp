//
//  LoginView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/22/26.
//

//
//  RegisterView.swift
//  ArduinoUrinalysis
//
//
//  RegisterView.swift
//  ArduinoUrinalysis
//

import SwiftUI
import SwiftData

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""

    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @State private var registrationSuccessful = false

    private let logic = AuthLogic()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 5) {

                    // MARK: - Header
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Join the Smart Urinalysis System")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 50)
                        .padding(24)
                    }
                    .frame(height: 150)
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            // MARK: - Username
                            Text("Username")
                                .fontWeight(.semibold)
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(
                                    icon: "person",
                                    placeholder: "e.g. john_doe",
                                    text: $username
                                )
                                Text("Letters, numbers, underscores, and hyphens only.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            // MARK: - Email
                            Text("Email")
                                .fontWeight(.semibold)
                            CustomTextField(
                                icon: "envelope",
                                placeholder: "Enter your email",
                                text: $email
                            )
                            .keyboardType(.emailAddress)

                            // MARK: - Password
                            Text("Password")
                                .fontWeight(.semibold)
                            VStack(alignment: .leading, spacing: 4) {
                                CustomSecureField(
                                    icon: "lock",
                                    placeholder: "Create a password",
                                    text: $password
                                )
                                Text("Minimum 6 characters.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            // MARK: - Confirm Password
                            Text("Confirm Password")
                                .fontWeight(.semibold)
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "Confirm your password",
                                text: $passwordConfirmation
                            )

                            // MARK: - Error Message
                            if let errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                }
                                .transition(.opacity)
                            }

                            // MARK: - Success Banner
                            if registrationSuccessful {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Account created! You can now log in.")
                                        .foregroundColor(.green)
                                        .font(.footnote)
                                }
                                .transition(.opacity)
                            }

                            // MARK: - Create Account Button
                            HStack {
                                Spacer()
                                Button(action: handleRegister) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        Text("Create Account")
                                            .bold()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .foregroundColor(.white)
                                    }
                                }
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                                .disabled(isLoading)
                                .frame(maxWidth: min(geometry.size.width, 500))
                                Spacer()
                            }
                            .padding(.top)

                            // MARK: - Back to Login
                            HStack {
                                Spacer()
                                Button {
                                    dismiss()
                                } label: {
                                    Text("Already have an account? Login")
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                            }
                        }
                        .frame(maxWidth: min(geometry.size.width, 500), alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .animation(.easeInOut, value: errorMessage)
                        .animation(.easeInOut, value: registrationSuccessful)
                    }
                }
            }
        }
    }

    // MARK: - Register Handler
    private func handleRegister() {
        errorMessage = nil
        registrationSuccessful = false
        isLoading = true

        do {
            _ = try logic.register(
                email: email,
                username: username,
                password: password,
                confirmPassword: passwordConfirmation,
                in: modelContext
            )
            registrationSuccessful = true
            // Give the user a moment to see the success banner, then dismiss back to Login
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred."
        }

        isLoading = false
    }
}

// MARK: - Reusable Field Components

struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(14)
    }
}

struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            SecureField(placeholder, text: $text)
                .autocorrectionDisabled(true)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(14)
    }
}

#Preview {
    RegisterView()
}
