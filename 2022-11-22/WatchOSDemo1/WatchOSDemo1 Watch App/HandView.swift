//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// This view represents a single of in our list
struct HandView: View {
    let imageName: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            makeImage(name: imageName, color: color)
            Spacer()
            Text(text)
                .multilineTextAlignment(.center)
            Spacer()
            makeImage(name: imageName, color: color)
        }
    }
    
    private func makeImage(name: String, color: Color) -> some View {
        Image(systemName: name)
            .foregroundColor(color)
    }
}

#if DEBUG
struct RowView_Previews: PreviewProvider {
    static var previews: some View {
        HandView(imageName: "suit.heart.fill", text: "Straight Flush", color: .red)
    }
}
#endif
