//
// Created by Joey Jarosz on 3/9/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Kingfisher
import MusicKit
import SwiftUI

struct TrackRowView: View {
    enum Constants {
        static let width = 60.0
        static let height = 60.0
    }
    
    var track: Track

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(track.title)
                    .font(.headline)
                
                Text(track.artistName)
                    .font(.caption)                
            }

            Spacer()
            
            if let duration = track.duration {
                Text(durationStr(from: duration))
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func durationStr(from duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let minutes = seconds / 60
        let remainder = seconds % 60
        
        return "\(minutes):\(remainder)"
    }
}

//#Preview {
//    TrackView()
//}
