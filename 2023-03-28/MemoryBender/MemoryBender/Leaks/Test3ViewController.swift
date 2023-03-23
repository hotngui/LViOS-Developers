//
// Created by Joey Jarosz on 3/21/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import os

///
///
class Test3ViewController: UIViewController {
    @IBOutlet private var textLabel1: UILabel!
    @IBOutlet private var textLabel2: UILabel!
    @IBOutlet private var textLabel3: UILabel!
    @IBOutlet private var toggle1: UISwitch!
    @IBOutlet private var toggle2: UISwitch!

    private var photos: [UIImage] = []
    private var previousImage: UIImage?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        if toggle1.isOn {
            photos.removeAll(keepingCapacity: false)
            updateLabels()
        }
    }
    
    // MARK: - Actions / Selectors

    @IBAction
    private func doneTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }

    @IBAction
    private func loadPhotos(_ sender: UIButton) {
        for _ in 0..<25 {
            if let image = UIImage(named: "House1") {
                if let newImage = self.generateNewImage(self.previousImage ?? image) {
                    if toggle2.isOn {
                        self.previousImage = newImage
                    }
                    
                    self.photos.append(newImage)
                    
                }
            }
        }

        self.updateLabels()
    }
    
    // MARK: - Utilities
    
    ///
    private func updateLabels() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let used = Memory.formattedBytes(Memory.memoryFootprint() ?? 0.0)
            let available = Memory.formattedBytes(Memory.availableMemory())
            
            self.textLabel1.text = "Memory USED: \(used)"
            self.textLabel2.text = "Memory AVAILABLE: \(available)"
            self.textLabel3.text = "Number of Photos: \(self.photos.count)"
        }
    }
    
    /// Given an image, generate and return a new one by pixallating it...
    ///
    private func generateNewImage(_ image: UIImage) -> UIImage? {
        guard let currentCGImage = image.cgImage else {
            return nil
        }
        
        let currentCIImage = CIImage(cgImage: currentCGImage)

        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currentCIImage, forKey: kCIInputImageKey)
        filter?.setValue(12, forKey: kCIInputScaleKey)

        guard let outputImage = filter?.outputImage else {
            return nil
        }

        let context = CIContext()

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        
        return nil
    }
}
