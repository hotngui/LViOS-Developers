//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct MyButton: View {
    @EnvironmentObject var currentSelection: Selection
    
    enum Constants {
        static let key = "Selection"
        static let dim = 60.0
    }
    
    let title: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8.0)
                .foregroundColor(color(for: title))
            
            Button(title) {
                buttonTapped(self.title)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(minWidth: Constants.dim, minHeight: Constants.dim, maxHeight: Constants.dim)
    }
    
    private func buttonTapped(_ title: String) {
        UserDefaults.standard.setValue(title, forKeyPath: Constants.key)
        currentSelection.current = title
    }
    
    private func color(for title: String) -> Color {
        if let selection = UserDefaults.standard.string(forKey: Constants.key) {
            if title == selection {
                return .red
            }
        }
        
        return .blue
    }
}

#if DEBUG
struct MyButton_Previews: PreviewProvider {
    static var previews: some View {
        MyButton(title: "Test")
            .tint(.blue)
    }
}
#endif
