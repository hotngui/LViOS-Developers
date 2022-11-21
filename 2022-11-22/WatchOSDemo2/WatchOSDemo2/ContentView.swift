//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model = CommsPhone()
    
    var body: some View {
        VStack {
            Text("Last Watch Selection")
                .font(.title)
                .foregroundColor(.blue)
            Text(getMessage())
                .foregroundColor(.red)
                .bold()
        }
        .padding()
    }
    
    func getMessage() -> String {
        if let selection = UserDefaults.standard.string(forKey: "Selection") {
            return selection
        }
        return "None"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
