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
import AuthenticationServices

@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var session: Session?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    private let supabase = SupabaseManager.shared
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var presentationAnchor: ASPresentationAnchor?

    override private init() {
        super.init()
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
        // Specify the iOS app's custom URL scheme for OAuth callback
        // This is critical for native app OAuth to work properly
        guard let redirectURL = URL(string: "viiraa://auth-callback") else {
            throw AuthError.invalidRedirectURL
        }

        // Get the OAuth URL from Supabase
        let oauthURL = try await supabase.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: redirectURL
        )

        // Present the OAuth flow using ASWebAuthenticationSession
        // This is critical to avoid Google's "disallowed_useragent" error
        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let authSession = ASWebAuthenticationSession(
                url: oauthURL,
                callbackURLScheme: "viiraa"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.noCallbackURL)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = false
            authSession.start()
        }

        // Exchange the callback URL for a session by letting Supabase handle the auth code
        // The callback URL contains parameters like ?code=xxx which Supabase will process
        try await supabase.auth.session(from: callbackURL)

        // After successful authentication, check the session
        if let currentSession = try? await supabase.auth.session {
            let session = convertSession(currentSession)
            await handleSuccessfulAuth(session: session)
        } else {
            throw AuthError.noSession
        }
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

        // Connect user to Junction if enabled
        if Constants.isJunctionEnabled {
            Task {
                do {
                    // Connect user to Junction
                    try await JunctionManager.shared.connectUser(userId: session.user.id)

                    // Request HealthKit permissions through Junction
                    try await JunctionManager.shared.requestHealthKitPermissions()

                    // Start automatic hourly sync
                    JunctionManager.shared.startAutomaticSync()

                    print("✅ User successfully connected to Junction and sync started")
                } catch {
                    // Log error but don't fail authentication
                    // Junction integration is optional and shouldn't block sign-in
                    print("⚠️ Failed to connect to Junction: \(error.localizedDescription)")

                    // Track Junction connection failure
                    AnalyticsManager.shared.track(event: "junction_connection_failed", properties: [
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }

    private func clearSession() async {
        // Disconnect from Junction if connected
        if Constants.isJunctionEnabled {
            JunctionManager.shared.disconnect()
        }

        keychain.clearSessionData()
        self.session = nil
        self.user = nil
        self.isAuthenticated = false
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the key window for presenting the authentication session
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Auth Errors

enum AuthError: Error {
    case noSession
    case invalidCredentials
    case networkError
    case invalidRedirectURL
    case noCallbackURL

    var localizedDescription: String {
        switch self {
        case .noSession:
            return "No session available"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .invalidRedirectURL:
            return "Invalid redirect URL configuration"
        case .noCallbackURL:
            return "No callback URL received from OAuth provider"
        }
    }
}
