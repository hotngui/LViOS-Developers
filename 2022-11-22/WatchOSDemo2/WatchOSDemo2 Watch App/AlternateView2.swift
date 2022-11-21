//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct AlternateView2: View {
    var body: some View {
        List {
            MyButton(title: "One")
            MyButton(title: "Two")
            MyButton(title: "Three")
            MyButton(title: "Four")
            MyButton(title: "Five")
            MyButton(title: "Six")
        }
    }
}

#if DEBUG
struct AlternateView2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AlternateView2()
                .previewDevice("Apple Watch Ultra (49mm)")
                .previewDisplayName("Ultra")
            AlternateView2()
                .previewDevice("Apple Watch Series 8 (41mm)")
                .previewDisplayName("41mm")
        }
    }
}
#endif
