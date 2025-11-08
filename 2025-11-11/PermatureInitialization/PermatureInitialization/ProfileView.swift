//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

var profileViewTaskCallCount = 0
var profileViewInitCallCount = 0

struct ProfileView: View {
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "person.fill")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Profile Tab")
                        .font(.title)
                }
            }
            .padding()
            .navigationTitle("Profile")
            .task {
                isLoading = true
                profileViewTaskCallCount += 1
                print("JOEY: ProfileView task modifier called (count: \(profileViewTaskCallCount))")
                
                try? await Task.sleep(for: .seconds(2))
                isLoading = false
            }
        }
    }
    
    init() {
        profileViewInitCallCount += 1
        print("JOEY: Initializing Profile View (count: \(profileViewInitCallCount))")
    }
}

#Preview {
    ProfileView()
}
