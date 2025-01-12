//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

// UIKit supports "readable content margins" in several ways including a
// `ReadableContentGuide` however SwiftUI does not have the same supports as of now.
//
// This View Modifier leans on UIKit to reproduce (approximately) the same behavior.
//
struct ReadableContentWidth: ViewModifier {
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation

    private let measureViewController = UIViewController()
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: readableWidth(for: orientation))
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
            }
    }
    
    private func readableWidth(for _: UIDeviceOrientation) -> CGFloat {
        measureViewController.view.frame = UIScreen.main.bounds
        measureViewController.view.preservesSuperviewLayoutMargins = true
                
        let readableContentSize = measureViewController.view.readableContentGuide.layoutFrame.size
        return readableContentSize.width
    }
}

public extension View {
    func readableContentWidth() -> some View {
        modifier(ReadableContentWidth())
    }
}
