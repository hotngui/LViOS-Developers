//
// Created by Joey Jarosz on 2/2/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

@MainActor
class ViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!

    typealias DataSource = UICollectionViewDiffableDataSource<String, User>

    private var users = [User]()
    private var dataSource: DataSource!

//    let url = URL(string: "http://www.hotngui.com/images/logo.png")!
//    let date = Date(timeIntervalSince1970: 1643985894.419055)

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        createLayout()
        configureDatasource()

        if let users = readData() {
            self.users = users
            updateUI(false)
        }
    }

    // MARK: - Layout

    private func createLayout() {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: config)

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Datasource

    private func configureDatasource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, User> { cell, indexPath, user in
            var contentConfig = UIListContentConfiguration.subtitleCell()

            contentConfig.text = "\(user.lastName), \(user.firstName)"
            contentConfig.secondaryText = "\(user.streetAddress), \(user.city) \(user.zipCode)"
            contentConfig.secondaryTextProperties.color = .secondaryLabel

            cell.contentConfiguration = contentConfig
        }

        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, user in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: user)
        }
    }

    private func updateUI(_ animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<String, User>()

        users.sort { user1, user2 in
            if user1.lastName == user2.lastName {
                return (user1.firstName < user2.firstName)
            } else if user1.lastName < user2.lastName {
                return true
            }
            return false
        }

        snapshot.appendSections(["main"])
        snapshot.appendItems(users)

        dataSource.apply(snapshot, animatingDifferences: animated)
    }

//    ///
//    func parseUser1() {
//        if let data = LocalJSONReader.read(from: "Users") {
//            let decoder = JSONDecoder()
//            let users = try? decoder.decode([User].self, from: data)
//
//            print(users!)
//        }
//
//
////        let user1 = User(birthday: date, lastName: "Jarosz", firstName: "Joey", streetAddress: "902 Pomeroy Ave", city: "Santa Clara", zipCode: 95051, avatar: url, classification: .nerd(level: 10))
////
////        let coder = JSONEncoder()
////        coder.outputFormatting = .prettyPrinted
////
////        let data = try? coder.encode(user1)
////
////        print(String(data: data!, encoding: .utf8)!)
//    }
//
//    ///
//    func parseUser2() {
//        if let data = LocalJSONReader.read(from: "Users") {
//            let decoder = JSONDecoder()
//            let users = try? decoder.decode([User2].self, from: data)
//
//            print(users!)
//        }
//
////        let user2 = User2(birthday: date, lastName: "Jarosz", firstName: "Joey", streetAddress: "902 Pomeroy Ave", city: "Santa Clara", zipCode: 95051, avatar: url, classification: .nerd(level: 10))
////
////        let coder = JSONEncoder()
////        coder.outputFormatting = .prettyPrinted
////
////        let data = try? coder.encode(user2)
////        print(String(data: data!, encoding: .utf8)!)
//    }
//
//    ///
//    func parseUser3() {
//        if let data = LocalJSONReader.read(from: "Users") {
//            if let objects = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [[String: Any]] {
//                var users = [User3]()
//
//                for object in objects! {
//                    if let user = User3(json: object) {
//                        users.append(user)
//                    }
//                }
//
//                print(users)
//            }
//        }
//
////        let user3 = User3(birthday: date, lastName: "Jarosz", firstName: "Joey", streetAddress: "902 Pomeroy Ave", city: "Santa Clara", zipCode: 95051, avatar: url, classification: .nerd(level: 10))
////
////        let data = try? JSONSerialization.data(withJSONObject: user3.toJSON(), options: [.prettyPrinted, .fragmentsAllowed])
////
////        print(String(data: data!, encoding: .utf8)!)
//    }
}

