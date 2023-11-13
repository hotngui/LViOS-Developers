//
// Created by Joey Jarosz on 10/10/23.
//

import Kingfisher
import SwiftUI

struct PhotoView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let urlStr: String
    let indx: Int

    private let ratio: CGFloat = 0.75
    private let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    
    var body: some View {
        VStack(spacing: 0) {
            KFImage
                .url(URL(string: urlStr))
                .fade(duration: 0.15)
                .placeholder { Image(.placeholder) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageWidth, height: imageWidth * ratio)
                .clipped()
                .background(Color(.systemGray4))

            Text("\(indx+1): \(urlStr)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 2, leading: 20, bottom: 0, trailing: 20))
        }
    }
    
    init(_ urlStr: String, indx: Int) {
        self.urlStr = urlStr
        self.indx = indx
    }
    
    private var imageWidth: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        
        for scene in scenes {
            if let scene = scene as? UIWindowScene {
                if let window = scene.windows.filter({ $0.isKeyWindow }).first {
                    if window.frame.width < window.frame.height {
                        return window.frame.width
                    } else {
                        return window.frame.height
                    }
                }
            }
        }
        
        return 0
    }
}

#Preview {
    Group {
        PhotoView("https://photos.zillowstatic.com/fp/da76aa88c3e4bafcc222bae3f14f73cd-p_f.jpg", indx: 0)
        PhotoView("https://photos.zillowstatic.com/fp/56f860b08c6eb60f0d63bb9ed75700b7-p_f.jpg", indx: 0)
    }
}
