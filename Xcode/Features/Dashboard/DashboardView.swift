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
                    Button(action: {
                        // Refresh WebView
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshWebView"), object: nil)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: Constants.primaryColorHex))
                    }
                }
            }
        }
        .onAppear {
            AnalyticsManager.shared.screen(name: "Dashboard")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}
