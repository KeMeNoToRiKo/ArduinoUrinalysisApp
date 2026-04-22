//
//  LoginView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/22/26.
//

import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("loggedInUsername") private var loggedInUsername: String = ""

    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var showRegister = false
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    private let logic = AuthLogic()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.05) {

                    // MARK: - Header
                    ZStack {
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(spacing: 12) {
                            Text("Smart Urinalysis")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Hydration Monitoring System")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 50)
                    }
                    .frame(height: 175)
                    .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 24) {
                        Text("Login to Continue")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(.label))

                        // MARK: - Identifier Field (auto-detects email vs username)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(identifier.contains("@") ? "Email" : "Username")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .animation(.easeInOut(duration: 0.2), value: identifier.contains("@"))

                            HStack {
                                Image(systemName: identifier.contains("@") ? "envelope" : "person")
                                    .foregroundColor(.gray)
                                    .animation(.easeInOut(duration: 0.2), value: identifier.contains("@"))

                                TextField("Email or username", text: $identifier)
                                    .keyboardType(identifier.contains("@") ? .emailAddress : .default)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }

                        // MARK: - Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.gray)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                SecureField("Enter your password", text: $password)
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }

                        // MARK: - Error Message
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .transition(.opacity)
                        }

                        // MARK: - Login Button
                        HStack {
                            Spacer()
                            Button(action: handleLogin) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Login")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(Color.blue)
                            .cornerRadius(16)
                            .disabled(isLoading)
                            .frame(maxWidth: min(geometry.size.width, 500))
                            .padding(.horizontal)
                            Spacer()
                        }

                        // MARK: - Register Button
                        HStack {
                            Spacer()
                            Button(action: { showRegister.toggle() }) {
                                Text("Register")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                            .frame(maxWidth: min(geometry.size.width, 500))
                            .padding(.horizontal)
                            Spacer()
                        }
                        .fullScreenCover(isPresented: $showRegister) {
                            RegisterView()
                        }
                    }
                    .padding(24)
                    .animation(.easeInOut, value: errorMessage)
                }
            }
        }
    }

    // MARK: - Login Handler
    private func handleLogin() {
        errorMessage = nil
        isLoading = true

        do {
            let user = try logic.login(identifier: identifier, password: password, in: modelContext)
            // Auth succeeded — flip the flag; ArduinoUrinalysisApp switches to ContentView
            loggedInUsername = user.username
            isLoggedIn = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred."
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
}
