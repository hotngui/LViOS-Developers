//
// Created by Joey Jarosz on 8/10/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var pushManager: PushNotificationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Remote Push Demo")
                .font(.title.bold())

            HStack {
                Button("Request Authorization") {
                    pushManager.requestAuthorizationAndRegister()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text(pushManager.authorizationStatusDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !pushManager.registrationErrorDescription.isEmpty {
                Text("Registration Error: \(pushManager.registrationErrorDescription)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if !pushManager.deviceTokenHex.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Token (hex)")
                        .font(.headline)
                    ScrollView(.horizontal) {
                        Text(pushManager.deviceTokenHex)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    HStack {
                        Button("Copy Token") {
                            UIPasteboard.general.string = pushManager.deviceTokenHex
                        }
                        .buttonStyle(.bordered)
                        .disabled(pushManager.deviceTokenHex.isEmpty)
                        Text("Copied!")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .opacity(0) // placeholder for quick UX; can be hooked to state later
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Last Tapped Payload Text")
                    .font(.headline)
                Text(pushManager.lastTappedPayloadText.isEmpty ? "(none yet)" : pushManager.lastTappedPayloadText)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
        .padding()
        .onAppear { pushManager.refreshAuthorizationStatus() }
    }
}

#Preview {
    ContentView().environmentObject(PushNotificationManager())
}
