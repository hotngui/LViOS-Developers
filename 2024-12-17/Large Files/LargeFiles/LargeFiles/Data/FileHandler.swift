//
// Created by Joey Jarosz on 12/7/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import Logging

@Observable
class FileHandler: NSObject, @unchecked Sendable {
    private let logger: Logger = Logger(label: "FileHandler")
    
    /// Step 1: Create a  URLSession based on a background configuration
    @ObservationIgnored
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "JoeySession")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private(set) var isBusy: Bool = false
    private(set) var error: String?
    private(set) var downloadSize: UInt64?

    private var task: URLSessionTask?
    private var fileName: String?

    // MARK: - Initializers
    
#if DEBUG
    init(mockIsBusy: Bool = false, mockError: String? = nil, mockDownloadSize: UInt64? = nil) {
        self.isBusy = mockIsBusy
        self.error = mockError
        self.downloadSize = mockDownloadSize
    }
#endif

    // MARK: - Download Support
    
    /// Step 2: Create and start a download task using the previously created URLSession
    func downloadFile(from url: URL) {
        fileName = url.lastPathComponent
        error = nil
        downloadSize = nil
        
        task = urlSession.downloadTask(with: url)
        task?.resume()
        
        isBusy = true
    }
    
    func cancelDownload() {
        task?.cancel()
        task = nil
        isBusy = false
    }
    
    // MARK: - Upload Support
    
    func uploadFile(to url: URL) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "PUT"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        
        let fm = FileManager.default
        let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docDir.appendingPathComponent("Test.txt")

        fileName = url.lastPathComponent
        error = nil
        downloadSize = nil

        task = urlSession.uploadTask(with: request, fromFile: fileURL)
        
        task?.resume()
        isBusy = true
    }
}

// MARK: - URLSessionDownloadDelegate Implementation

extension FileHandler: URLSessionDownloadDelegate {
    // Step 3: When the download finishes we need to move it to its final destination
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fm = FileManager.default
        let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newLocation = docDir.appendingPathComponent(fileName!)
        
        try? fm.removeItem(at: newLocation)
        try! fm.copyItem(at: location, to: newLocation)
        
        let attributes = try? fm.attributesOfItem(atPath: newLocation.path)
        
        Task { @MainActor in
            downloadSize = attributes?[.size] as? UInt64
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            downloadSize = UInt64(totalBytesWritten)
            logger.info("didWriteData: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if task === self.task {
            Task { @MainActor in
                self.error = error?.localizedDescription
                self.isBusy = false
                
                if let error = error {
                    logger.error("Task failed with error: \(error)")
                } else {
                    logger.info("Task completed successfully.")
                }
            }
        } else {
            task.cancel()
            self.task = nil
        }
    }
}
