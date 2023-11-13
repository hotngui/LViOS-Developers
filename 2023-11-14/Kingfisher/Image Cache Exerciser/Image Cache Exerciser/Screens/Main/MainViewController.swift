//
// Created by Joey Jarosz on 9/21/23.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet private weak var photoCountSlider: UISlider!
    @IBOutlet private weak var photoCountPrompt: UILabel!
    @IBOutlet private weak var photoCountMaxLabel: UILabel!
    @IBOutlet private weak var imageSizeSelector: UISegmentedControl!
    @IBOutlet private weak var toolkitSelector: UISegmentedControl!
    @IBOutlet private weak var cacheTypeSelector: UISegmentedControl!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    private enum Property: String {
        case photoCount
        case imageSize
        case toolkit
        case cacheType
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDefaultValues()
        
        Cache.default.configure(for: mapCacheType(indx: cacheTypeSelector.selectedSegmentIndex))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "ShowHostingController" {
            if let vc = segue.destination as? PhotoViewHostingController {
                vc.model.paths = imagePaths()
            }
        }
    }
    
    // MARK: - Actions / Selections
    
    @IBAction
    private func openViewTapped(_ sender: Any) {
        if toolkitSelector.selectedSegmentIndex == 0 {
            performSegue(withIdentifier: "Show Photos", sender: self)
        } else {
            performSegue(withIdentifier: "ShowHostingController", sender: self)
        }
    }
    
    @IBAction
    private func clearCacheTapped(_ sender: Any) {
        Task {
            spinner.startAnimating()            
            await Cache.default.clear()
            spinner.stopAnimating()
        }
    }
    
    @IBAction
    private func preloadCacheTapped(_ sender: Any) {
        Task {
            spinner.startAnimating()
            await Cache.default.preload(with: imagePaths())
            spinner.stopAnimating()
        }
    }
    
    @IBAction
    private func dumpStatsTapped(_ sender: Any) {
        let stats = Cache.default.dumpStats(photoCount: Self.getPhotoCount(), imageSize: Self.getImageSize(), toolkit: Self.getToolkitValue())
        let statsVC = StatsViewHostingController(data: stats)

        present(statsVC, animated: true)
    }
    
    @IBAction
    private func photoCountSliderChanged(_ sender: Any) {
        updatePhotoCountLabel()
        storePhotoCount()
    }
    
    @IBAction
    private func imageSizeValueChanged(_ sender: Any) {
        storeImageSize()
    }
    
    @IBAction
    private func toolkitValueChanged(_ sender: Any) {
        storeToolkit()
    }
    
    @IBAction
    private func cacheTypeChangedValue(_ sender: UISegmentedControl) {
        storeCacheType()
        
        Task {
            spinner.startAnimating()
            await Cache.default.clear()
            Cache.default.configure(for: mapCacheType(indx: sender.selectedSegmentIndex))
            spinner.stopAnimating()
        }
    }
    
    // MARK: - Segue Actions
    
    @IBSegueAction
    private func makePhotoViewerViewController(_ coder: NSCoder) -> PhotoViewerViewController? {
        return PhotoViewerViewController(paths: imagePaths(), coder: coder)
    }
    
    // I really want to do this, but since UIHostingController is a generic class and Segue Actions must return an
    // object that is supported by Objective-C I am out of luck...
    //@IBSegueAction
    //private func makePhotoViewerHostingController(_ coder: NSCoder) -> PhotoViewHostingController? {
    //    return PhotoViewHostingController(paths: imagePaths(), coder: coder)
    //}
    
    // MARK: - Default Values
    
    private func setupDefaultValues() {
        if isViewLoaded {
            let maxCnt = ImageProvider.default.maxCount
            
            photoCountMaxLabel.text = "\(maxCnt)"
            photoCountSlider.maximumValue = Float(maxCnt)

            // Set bare bone default values...
            photoCountSlider.value = Float(maxCnt)
            imageSizeSelector.selectedSegmentIndex = 1
            toolkitSelector.selectedSegmentIndex = 0
            cacheTypeSelector.selectedSegmentIndex = 0
        
            // Get values from preferences, if they exist...
            retrievePhotoCount()
            retrieveImageSize()
            retrieveToolkit()
            retrieveCacheType()
            
            //
            updatePhotoCountLabel()
        }
    }
    
    // MARK: - Utility Methods
    
    private func updatePhotoCountLabel() {
        photoCountPrompt.text = "Photo Count (\(Int(photoCountSlider.value)))"
    }
    
    private func imagePaths() -> [String] {
        let cnt = Int(photoCountSlider.value)
        let resolution: ImageProvider.Resolution = (imageSizeSelector.selectedSegmentIndex == 0 ? .medium : .high)

        return ImageProvider.default.urls(first: cnt, at: resolution)
    }
    
    private func mapCacheType(indx: Int) -> Cache.CacheType {
        switch cacheTypeSelector.titleForSegment(at: indx) {
        case Cache.CacheType.factory.rawValue:
            return .factory
            
        case Cache.CacheType.memory.rawValue:
            return .memory
            
        case Cache.CacheType.disk.rawValue:
            return .disk
            
        default:
            return .factory
        }
    }
    
    // MARK: - Store/Restore Settings
    
    private func storePhotoCount() {
        let cnt = Int(photoCountSlider.value)
        UserDefaults.standard.setValue(cnt, forKey: Property.photoCount.rawValue)
    }
    
    private func storeImageSize() {
        if let choice = imageSizeSelector.titleForSegment(at: imageSizeSelector.selectedSegmentIndex) {
            UserDefaults.standard.setValue(choice, forKey: Property.imageSize.rawValue)
        } else {
            UserDefaults.standard.removeObject(forKey: Property.imageSize.rawValue)
        }
    }
    
    private func storeToolkit() {
        if let choice = toolkitSelector.titleForSegment(at: toolkitSelector.selectedSegmentIndex) {
            UserDefaults.standard.setValue(choice, forKey: Property.toolkit.rawValue)
        } else {
            UserDefaults.standard.removeObject(forKey: Property.toolkit.rawValue)
        }
    }
    
    private func storeCacheType() {
        if let choice = cacheTypeSelector.titleForSegment(at: cacheTypeSelector.selectedSegmentIndex) {
            UserDefaults.standard.setValue(choice, forKey: Property.cacheType.rawValue)
        } else {
            UserDefaults.standard.removeObject(forKey: Property.cacheType.rawValue)
        }
    }
    
    private func retrievePhotoCount() {
        let value = Self.getPhotoCount()
        
        if value > 0 {
            photoCountSlider.value = Float(value)
        } else {
            storePhotoCount()
        }
    }
    
    private func retrieveImageSize() {
        if let value = Self.getImageSize() {
            for i in 0..<imageSizeSelector.numberOfSegments {
                if imageSizeSelector.titleForSegment(at: i) == value {
                    imageSizeSelector.selectedSegmentIndex = i
                    break
                }
            }
        } else {
            storeImageSize()
        }
    }
    
    private func retrieveToolkit() {
        if let value = Self.getToolkitValue() {
            for i in 0..<toolkitSelector.numberOfSegments {
                if toolkitSelector.titleForSegment(at: i) == value {
                    toolkitSelector.selectedSegmentIndex = i
                    break
                }
            }
        } else {
            storeToolkit()
        }
    }
    
    private func retrieveCacheType() {
        if let value = UserDefaults.standard.string(forKey: Property.cacheType.rawValue) {
            for i in 0..<cacheTypeSelector.numberOfSegments {
                if cacheTypeSelector.titleForSegment(at: i) == value {
                    cacheTypeSelector.selectedSegmentIndex = i
                    break
                }
            }
        }
    }
    
    static func getPhotoCount() -> Int {
        return UserDefaults.standard.integer(forKey: Property.photoCount.rawValue)
    }
    
    static func getToolkitValue() -> String? {
        return UserDefaults.standard.string(forKey: Property.toolkit.rawValue)
    }
    
    static func getImageSize() -> String? {
        return UserDefaults.standard.string(forKey: Property.imageSize.rawValue)
    }
}
