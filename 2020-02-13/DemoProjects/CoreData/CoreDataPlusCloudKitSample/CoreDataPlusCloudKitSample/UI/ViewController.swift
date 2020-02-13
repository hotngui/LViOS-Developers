//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import CoreData

///
///
class ViewController: UITableViewController {
    var dataStore = DataStore()
    var fetchedResultsController: NSFetchedResultsController<Restaurant>?

    var diffableDataSource: UITableViewDiffableDataSource<Int, Restaurant>?
    var diffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Int, Restaurant>()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // This gets rid of those annoying separator lines for rows that don't exist.
        tableView.tableFooterView = UIView()

        setupTableView()

        // We use a Fetch Results Controller to link our CoreData items to our tableView.
        //
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        
        request.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: dataStore.container.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        fetchedResultsController?.delegate = self

        do {
            try fetchedResultsController?.performFetch()
            setupSnapshot()
        } catch {
            print("Fetch Error: \(error)")
            // Failed to fetch results from the database. Handle errors appropriately in your app.
        }
    }

    // MARK: - Actions

    /// Create a new piece of data to be added to the database...
    /// - Parameter sender: The button that was tapped
    ///
    @IBAction private func addDataTapped(_ sender: UIBarButtonItem) {
        let address = Address(context: dataStore.container.viewContext)
        let restaurant = Restaurant(context: dataStore.container.viewContext)

        let piece = ["Famous", "Original", "Famous Original"]
        let indx = Int.random(in: 0..<3)

        address.street = "123 5th Ave."
        address.city = "New York"
        address.state = "NY"

        restaurant.name = "\(piece[indx]) Ray's Pizza"
        restaurant.address = address

        dataStore.saveContext()
    }

    // MARK: - Private Methods

    private func setupTableView() {
        diffableDataSource = UITableViewDiffableDataSource<Int, Restaurant>(tableView: tableView) { (tableView, indexPath, item) -> UITableViewCell? in
            if let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as? RestaurantCell {
                let name = "\(item.name ?? "")"
                let address = "\(item.address?.street ?? ""), \(item.address?.city ?? "") \(item.address?.state ?? "")"

                cell.configure(name: name, address: address)
                return cell
            }

            preconditionFailure()
        }

        setupSnapshot()
    }

    private func setupSnapshot() {
        diffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Int, Restaurant>()
        diffableDataSourceSnapshot.appendSections([0])
        diffableDataSourceSnapshot.appendItems(fetchedResultsController?.fetchedObjects ?? [])

        diffableDataSource?.apply(diffableDataSourceSnapshot)
    }
}

///
///
extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}
