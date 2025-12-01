//
//  DashboardView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var showMenu = false
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false

    private var dashboardURL: URL {
        guard let url = URL(string: Constants.dashboardURL) else {
            fatalError("Invalid dashboard URL")
        }
        return url
    }

    var body: some View {
        NavigationView {
            ZStack {
                DashboardWebView(
                    url: dashboardURL,
                    session: authManager.session,
                    isLoading: $isLoading
                )
                .edgesIgnoringSafeArea(.bottom)

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            // Refresh WebView
                            NotificationCenter.default.post(name: NSNotification.Name("RefreshWebView"), object: nil)
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color(hex: Constants.primaryColorHex))
                        }

                        Menu {
                            Button(role: .destructive, action: {
                                showSignOutConfirmation = true
                            }) {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Color(hex: Constants.primaryColorHex))
                        }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out? This is an emergency sign-out option that works even if the web dashboard is unavailable.")
            }
        }
        .onAppear {
            AnalyticsManager.shared.screen(name: "Dashboard")
        }
    }

    private func handleSignOut() {
        isSigningOut = true
        Task {
            do {
                try await authManager.signOut()
                AnalyticsManager.shared.track(event: "user_signed_out", properties: ["source": "dashboard_menu"])
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
