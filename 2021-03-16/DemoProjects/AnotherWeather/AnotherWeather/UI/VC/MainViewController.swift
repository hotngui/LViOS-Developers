//
// Created by Joey Jarosz on 3/6/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import Kingfisher

///
class MainViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var lastCheckedLabel: UILabel!
    @IBOutlet private weak var temperatureLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var busyView: UIActivityIndicatorView!

    private let defaults = Defaults()
    private let weatherApi = WeatherAPI()
    private var location: String?

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        clearResults()
        busyView.startAnimating()

        var currentLocation: String

        if let defaultLocation = defaults.getLocation() {
            currentLocation = defaultLocation
        } else {
            currentLocation = "Las Vegas, Nevada"
        }

        location = currentLocation
        getWeather(for: currentLocation)
    }

    // MARK: - Segue Actions

    @IBSegueAction
    func showLocationSelector(_ coder: NSCoder) -> LocationViewController? {
        let vc = LocationViewController(coder: coder) { [weak self] (location) in
            guard let self = self else { return }

            if let location = location {
                self.clearResults()
                self.busyView.startAnimating()

                self.defaults.storeLocation(location)
                self.getWeather(for: location)
            }

            self.presentedViewController?.dismiss(animated: true)
        }

        return vc
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func refreshTapped(_ sender: Any) {
        clearResults()
        busyView.startAnimating()

        if let location = self.location {
            getWeather(for: location)
        }
    }

    // MARK: - Private Methods

    private func getWeather(for location: String) {
        weatherApi.current(for: location) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.sync {
                self.busyView.stopAnimating()

                switch result {
                case .failure(let error):
                    self.complainAboutError(error)

                case .success(let weather):
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                    let viewModel = WeatherViewModel(with: weather)

                    self.locationLabel.text = "\(viewModel.city), \(viewModel.state)"
                    self.lastCheckedLabel.text = dateFormatter.string(from: viewModel.lastCheckedTime)
                    self.descriptionLabel.text = viewModel.description
                    self.temperatureLabel.text = viewModel.temperature
                    self.imageView.kf.setImage(with: viewModel.iconUrl)
                }
            }
        }
    }

    private func clearResults() {
        self.locationLabel.text = " "
        self.lastCheckedLabel.text = " "
        self.descriptionLabel.text = " "
        self.temperatureLabel.text = " "
        self.imageView.image = nil
    }

    private func complainAboutError(_ error: Error) {
        let alert = UIAlertController(title: "Oops!", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))

        present(alert, animated: true)
    }
}
