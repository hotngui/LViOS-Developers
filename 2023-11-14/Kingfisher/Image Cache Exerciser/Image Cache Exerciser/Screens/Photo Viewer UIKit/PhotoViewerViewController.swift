//
// Created by Joey Jarosz on 9/21/23.
//

import UIKit

class PhotoViewerViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    
    private enum Section: Int {
        case main
    }
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, String>
    
    private var urlStrings: [String]
    private var dataSource: DataSource!
    
    // MARK: - View Lifecycle
    
    init?(paths: [String], coder: NSCoder) {
        urlStrings = paths
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.prefetchDataSource = self
        
        dataSource = configureDataSource(for: tableView)
        update(dataSource, with: urlStrings)

//        // Example of how to pre-fetch the first few images since the tableView prefetcher does not handle them...
//        let resolution: ImageProvider.Resolution = .high
//        let preload = ImageProvider.default.urls(first: 3, at: resolution)
//
//        Cache.default.preload(with: preload)
    }
    
    // MARK: - Actions / Selectors
    
    @IBAction
    private func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction
    private func dumpStatsTapped(_ sender: Any) {
        let stats = Cache.default.dumpStats(photoCount: MainViewController.getPhotoCount(), imageSize: MainViewController.getImageSize(), toolkit: MainViewController.getToolkitValue())
        let statsVC = StatsViewHostingController(data: stats)
        
        present(statsVC, animated: true)
    }
    
    // MARK: - DataSource
    
    private func configureDataSource(for tableView: UITableView) -> DataSource {
        let dataSource = DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCellView", for: indexPath) as? PhotoCellView {
                cell.configure(with: itemIdentifier, indx: indexPath.row)
                return cell
            }
            
            return nil
        }
        
        return dataSource
    }
    
    private func update(_ dataSource: DataSource, with data: [String]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        
        snapshot.appendSections([.main])
        snapshot.appendItems(data)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

//extension PhotoViewerViewController: UITableViewDataSourcePrefetching {
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        //print("Prefetch: \(indexPaths)")
//    }
//}
