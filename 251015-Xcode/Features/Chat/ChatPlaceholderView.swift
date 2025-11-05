//
//  ChatPlaceholderView.swift
//  ViiRaaApp
//
//  Created by ViiRaa Team
//  Copyright © 2025 ViiRaa. All rights reserved.
//

import SwiftUI

struct ChatPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("Chat Coming Soon")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("AI coach chat will be available in a future update")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

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
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            AnalyticsManager.shared.screen(name: "ChatPlaceholder")
        }
    }
}

#Preview {
    ChatPlaceholderView()
}
