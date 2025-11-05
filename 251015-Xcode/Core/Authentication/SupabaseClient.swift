//
//  SupabaseClient.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import Foundation
import Supabase

extension Notification.Name {
    static let supabaseAuthStateChanged = Notification.Name("supabaseAuthStateChanged")
}

class SupabaseManager {
    static let shared = SupabaseManager()

    private(set) var client: SupabaseClient!
    var auth: AuthClient { client.auth }

    // Use from(_:) method instead of deprecated database property
    func from(_ table: String) -> PostgrestQueryBuilder {
        return client.from(table)
    }

    func rpc<T: Decodable, P: Encodable>(_ function: String, params: P? = nil) async throws -> T {
        if let params = params {
            return try await client.rpc(function, params: params).execute().value
        } else {
            return try await client.rpc(function).execute().value
        }
    }

    private init() {}

    func initialize() {
        guard let url = URL(string: Constants.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Constants.supabaseAnonKey
        )

        // Listen for auth state changes
        Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .supabaseAuthStateChanged,
                        object: state
                    )
                }
            }
        }
    }
}
