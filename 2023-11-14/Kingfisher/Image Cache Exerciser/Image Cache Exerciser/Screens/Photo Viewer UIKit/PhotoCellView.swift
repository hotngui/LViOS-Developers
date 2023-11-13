//
// Created by Joey Jarosz on 9/15/23.
//

import Kingfisher
import UIKit

///
class PhotoCellView: UITableViewCell {
    @IBOutlet private weak var photoView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    
    func configure(with urlStr: String, indx: Int) {
        label.text = "\(indx+1): \(urlStr)"
        
        if let url = URL(string: urlStr) {
            photoView.kf.setImage(with: url, 
                                  placeholder: UIImage(resource: .placeholder),
                                  options: [
                                    .transition(.fade(0.15))
                                  ])
        } else {
            photoView.image = nil
        }
    }
}
