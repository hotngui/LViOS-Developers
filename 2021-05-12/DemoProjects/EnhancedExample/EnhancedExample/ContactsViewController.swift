//
// Created by Joey Jarosz on 5/10/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!

    private enum Section {
        case main
    }

    private lazy var contacts: [Contact] = {
        return Results.loadSampleData()
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Contact>?
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        applySnapshot(false)
    }

    // MARK: - CollectionView Configuration

    private func configureCollectionView() {
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)

        collectionView.collectionViewLayout = listLayout

        dataSource = UICollectionViewDiffableDataSource<Section, Contact>(collectionView: collectionView) { (collectionView, indexPath, contact) -> UICollectionViewCell? in
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath) as? ContactCell {
                cell.configure(contact)
                return cell
            }

            return nil
        }
    }

    private func applySnapshot(_ animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Contact>()
        snapshot.appendSections([.main])
        snapshot.appendItems(contacts, toSection: .main)

        dataSource?.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - CollectionView Cell Definitions

class ContactCell: UICollectionViewCell {
    @IBOutlet private weak var name: UILabel!
    @IBOutlet private weak var address: UILabel!

    func configure(_ contact: Contact) {
        name.text = "\(contact.lastName), \(contact.firstName)"
        address.text = "\(contact.streetAddress), \(contact.city), \(contact.stateShort) \(contact.zipCode)"

        ///
        /// Combined individual pieces of text and gather up buttons into center an array of custom actions to help keep them in useful context
        ///
        isAccessibilityElement = true
        accessibilityLabel = "\(contact.firstName) \(contact.lastName), lives at \(contact.streetAddress), \(contact.city), \(contact.stateLong) \(contact.zipCode)"

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Call", target: self, selector: #selector(callTapped(_:))),
            UIAccessibilityCustomAction(name: "Send a Message", target: self, selector: #selector(textTapped(_:)))
        ]
    }

    @IBAction private func callTapped(_ sender: UIButton) {
        print("Call Tapped")
    }

    @IBAction private func textTapped(_ sender: UIButton) {
        print("Text Tapped")
    }
}
