//
//  ChatPlaceholderView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//
//  Updated: 2025-11-20 - Added WhatsApp redirect for interim support

import SwiftUI

struct ChatPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: Constants.primaryColorHex))

                Text("Chat with our Team")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Chat with our team on WhatsApp while we build our native chat feature")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    openWhatsApp()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                        Text("Open WhatsApp")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: Constants.primaryColorHex))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)

                Text("This is a temporary solution. Native chat coming soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                Spacer()

                // Preview of upcoming features
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: Constants.primaryColorHex))
                        Text("Real-time messaging")
                            .font(.subheadline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: Constants.primaryColorHex))
                        Text("AI-powered health coaching")
                            .font(.subheadline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: Constants.primaryColorHex))
                        Text("Personalized insights")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            AnalyticsManager.shared.screen(name: "ChatWhatsApp")
        }
    }

    private func openWhatsApp() {
        // WhatsApp contact link
        let whatsappURL = URL(string: "https://wa.me/18882087058")!

        // Track analytics
        AnalyticsManager.shared.track(event: "whatsapp_redirect_clicked", properties: [
            "from": "chat_tab"
        ])

        // Open WhatsApp
        if UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL)
        } else {
            print("Cannot open WhatsApp URL")
        }
    }
}

#Preview {
    ChatPlaceholderView()
}
