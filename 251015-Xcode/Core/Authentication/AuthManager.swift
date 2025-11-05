//
//  AuthManager.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import Foundation
import Combine
import Supabase
import UIKit

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var session: Session?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    private let supabase = SupabaseManager.shared
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
        checkExistingSession()
    }

    private func setupAuthStateListener() {
        // Listen to auth state changes from Supabase
        NotificationCenter.default.publisher(for: .supabaseAuthStateChanged)
            .sink { [weak self] notification in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.handleAuthStateChange(notification)
                }
            }
            .store(in: &cancellables)
    }

    private func handleAuthStateChange(_ notification: Notification) async {
        // Handle auth state changes if needed
        if let state = notification.object as? AuthChangeEvent {
            switch state {
            case .signedIn, .tokenRefreshed, .initialSession:
                // Reload session
                if let session = try? await supabase.auth.session {
                    await handleSuccessfulAuth(session: convertSession(session))
                }
            case .signedOut:
                await clearSession()
            default:
                break
            }
        }
    }

    private func checkExistingSession() {
        Task {
            do {
                // Try to get current session from Supabase SDK
                let currentSession = try await supabase.auth.session

                // If we have a valid session from Supabase, use it
                let session = convertSession(currentSession)
                await handleSuccessfulAuth(session: session)
            } catch {
                // No valid session exists, user needs to sign in
                print("No existing session found: \(error.localizedDescription)")
                await clearSession()
            }

            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func convertSession(_ supabaseSession: Supabase.Session) -> Session {
        return Session(
            accessToken: supabaseSession.accessToken,
            refreshToken: supabaseSession.refreshToken,
            expiresIn: Int(supabaseSession.expiresIn),
            tokenType: supabaseSession.tokenType,
            user: convertUser(supabaseSession.user)
        )
    }

    private func convertUser(_ authUser: Auth.User) -> User {
        return User(
            id: authUser.id.uuidString,
            email: authUser.email ?? "",
            createdAt: authUser.createdAt,
            lastSignInAt: authUser.lastSignInAt,
            userMetadata: nil
        )
    }

    func signInWithGoogle() async throws {
        // Launch Google OAuth flow
        let oauthSession = try await supabase.auth.signInWithOAuth(provider: .google)
        let session = convertSession(oauthSession)
        await handleSuccessfulAuth(session: session)
    }

    func signInWithPassword(email: String, password: String) async throws {
        let supabaseSession = try await supabase.auth.signIn(email: email, password: password)
        let session = convertSession(supabaseSession)
        await handleSuccessfulAuth(session: session)
    }

    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)

        guard let authSession = response.session else {
            throw AuthError.noSession
        }

        let session = convertSession(authSession)
        await handleSuccessfulAuth(session: session)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        await clearSession()
    }

    private func handleSuccessfulAuth(session: Session) async {
        // Store session in keychain
        if let sessionData = try? JSONEncoder().encode(session) {
            keychain.saveSessionData(sessionData)
        }

        self.session = session
        self.user = session.user
        self.isAuthenticated = true

        // Track sign-in event
        AnalyticsManager.shared.track(event: "user_signed_in", properties: [
            "method": "email" // or "google"
        ])
    }

    private func clearSession() async {
        keychain.clearSessionData()
        self.session = nil
        self.user = nil
        self.isAuthenticated = false
    }
}

// MARK: - Auth Errors

enum AuthError: Error {
    case noSession
    case invalidCredentials
    case networkError

    var localizedDescription: String {
        switch self {
        case .noSession:
            return "No session available"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        }
    }
}
