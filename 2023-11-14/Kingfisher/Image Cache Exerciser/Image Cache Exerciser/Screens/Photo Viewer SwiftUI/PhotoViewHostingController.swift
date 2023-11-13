//
// Created by Joey Jarosz on 10/10/23.
//

import SwiftUI
import UIKit

///
///
class PhotoViewHostingController: UIHostingController<PhotoViewer> {
    var model = DataModel()
    
     // MARK: - Initilizers

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: PhotoViewer(model));
    }
}

///
class DataModel: ObservableObject {
    @Published var paths: [String]
    
    init() {
        paths = []
    }
    
    init(_ paths: [String]) {
        self.paths = paths
    }
}
