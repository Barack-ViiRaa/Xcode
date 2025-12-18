//
//  ErrorLogView.swift
//  ViiRaa
//
//  Created by Claude Code on 2025-12-18.
//  View error logs for debugging on physical devices (Bug #22 fix)
//

import SwiftUI

struct ErrorLogView: View {
    @State private var logContents: String = ""
    @State private var isRefreshing = false
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Log")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("This log helps diagnose issues on physical devices where Xcode console isn't available.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Refresh Button
                Button(action: refreshLog) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .disabled(isRefreshing)

                // Log Contents
                VStack(alignment: .leading) {
                    if logContents.isEmpty {
                        Text("No logs available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text(logContents)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                // Share Button
                if !logContents.isEmpty {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Log")
                        }
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingShareSheet) {
                        ShareSheet(items: [logContents])
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Error Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLog()
        }
    }

    private func loadLog() {
        logContents = ErrorLogger.shared.getLogContents()
    }

    private func refreshLog() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadLog()
            isRefreshing = false
        }
    }
}

// UIActivityViewController wrapper for sharing
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    NavigationView {
        ErrorLogView()
    }
}
