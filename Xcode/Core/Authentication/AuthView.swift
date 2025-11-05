//
//  AuthView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: Constants.primaryColorHex).opacity(0.1)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(hex: Constants.primaryColorHex))

                        Text(Constants.appName)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)

                        Text("From Weight Control, To Body Intelligence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: handleEmailAuth) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: Constants.primaryColorHex))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        Button(action: {
                            isSignUp.toggle()
                            errorMessage = nil
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: Constants.primaryColorHex))
                        }
                    }
                    .padding(.horizontal, 32)

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 32)

                    // Google Sign In
                    Button(action: handleGoogleAuth) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)
                    .disabled(isLoading)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func handleEmailAuth() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signInWithPassword(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func handleGoogleAuth() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
}
