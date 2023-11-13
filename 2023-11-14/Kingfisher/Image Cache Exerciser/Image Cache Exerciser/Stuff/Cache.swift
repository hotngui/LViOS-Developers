//
// Created by Joey Jarosz on 9/22/23.
// 
//

import Foundation
import Kingfisher

class Cache: CacheProtocol {
    static var `default` = Cache()
    private(set) var cacheType: CacheType = .factory
    
    private let defaultOptions: KingfisherOptionsInfo
    
    enum CacheType: String {
        case factory = "Default"
        case memory = "Memory"
        case disk = "Disk"
    }
    
    private init() {
        self.defaultOptions = KingfisherManager.shared.defaultOptions
    }
}

// MARK: - CacheProtocol Implementation

extension Cache {
    func clear() async {
        await withCheckedContinuation { continuation in
            ImageCache.default.clearDiskCache {
                ImageCache.default.clearMemoryCache()
                continuation.resume()
            }
        }
    }
    
    func preload(with urlPaths: [String]) async {
        let urls = urlPaths.map { URL(string: $0)! }
        
        var options: KingfisherOptionsInfo?
        
        if cacheType == .memory {
            options = [
                .cacheMemoryOnly,
                .alsoPrefetchToMemory
            ]
        }
        
        await withCheckedContinuation { continuation in
            let prefetcher = ImagePrefetcher(urls: urls, options: options) { skipped, failed, good in
                continuation.resume()
            }
            prefetcher.start()
        }
    }
    
    func configure(for cacheType: CacheType) {
        let cache = ImageCache.default
        let totalMemory = ProcessInfo.processInfo.physicalMemory

        self.cacheType = cacheType
        
        switch cacheType {
        case .memory:
            
            KingfisherManager.shared.defaultOptions = [
                .cacheMemoryOnly
            ]
            
            cache.memoryStorage.config.totalCostLimit = 0
            cache.memoryStorage.config.countLimit = 0
            cache.memoryStorage.config.keepWhenEnteringBackground = true

            cache.diskStorage.config.sizeLimit = 1
            cache.diskStorage.config.expiration = .expired

        case .disk:
            KingfisherManager.shared.defaultOptions = defaultOptions
            
            cache.memoryStorage.config.totalCostLimit = 0
            cache.memoryStorage.config.countLimit = 0
            cache.memoryStorage.config.keepWhenEnteringBackground = false
            cache.memoryStorage.config.expiration = .expired
            
            cache.diskStorage.config.sizeLimit = 0
            cache.diskStorage.config.expiration = .never

        case .factory:
            KingfisherManager.shared.defaultOptions = defaultOptions

            cache.memoryStorage.config.totalCostLimit = Int(totalMemory / 4)
            cache.memoryStorage.config.countLimit = .max
            cache.memoryStorage.config.expiration = .seconds(300)
            cache.memoryStorage.config.keepWhenEnteringBackground = false
            cache.memoryStorage.config.cleanInterval = 120

            cache.diskStorage.config.sizeLimit = 0
            cache.diskStorage.config.expiration = .days(7)
        }
    }
    
    func dumpStats(photoCount: Int? = nil, imageSize: String? = nil, toolkit: String? = nil) -> [(String, String)] {
        let cache = ImageCache.default
        let url = cache.diskStorage.directoryURL

        let totalMemory = ByteCountFormatter().string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))
        let appUsedMemory = ByteCountFormatter().string(fromByteCount: Int64(usedMemory()))
        
        let diskUsed = ByteCountFormatter().string(fromByteCount: usedDisk(for: url))

        return [
            ("Cache:", "Kingfisher"),
            ("Type:", Cache.default.cacheType.rawValue),
            ("Photo Count:", "\(photoCount ?? -1)"),
            ("Image Size:", "\(imageSize ?? "")"),
            ("Toolkit:", "\(toolkit ?? "")"),
            ("", ""),
            ("Device", ""),
            ("Total System Memory:", totalMemory),
            ("App Used Memory:", appUsedMemory),
            ("App Used Disk:", diskUsed),
            ("", ""),
            ("Memory Config", ""),
            ("Cost Limit:", "\(cache.memoryStorage.config.totalCostLimit)"),
            ("Count Limit:", "\(cache.memoryStorage.config.countLimit)"),
            ("Expiration", "\(cache.memoryStorage.config.expiration)"),
            ("Keep Background", "\(cache.memoryStorage.config.keepWhenEnteringBackground)"),
            ("Clean Interval", "\(cache.memoryStorage.config.cleanInterval)"),
            ("", ""),
            ("Disk Config", ""),
            ("Disk Count Limit:", "\(cache.diskStorage.config.sizeLimit)"),
            ("Disk Expiration", "\(cache.diskStorage.config.expiration)")
        ]
    }
}

// MARK: - Utility Methods for Reporting

extension Cache {
    func usedMemory() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        var used: UInt64 = 0
        
        if result == KERN_SUCCESS {
            used = UInt64(taskInfo.phys_footprint)
        }
        
        return used
    }
    
    func usedDisk(for url: URL) ->  Int64 {
        var size: Int64 = 0
        
        walkDirectory(at: url, options: []) { sz in
            if let sz {
                size += sz
            }
        }
        
        return size
    }
    
    func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions, completion: ((Int64?) -> Void)) {
        let fm = FileManager.default
        let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.hasDirectoryPath {
                walkDirectory(at: fileURL, options: options, completion: completion)
            } else {
                completion(fm.sizeOfFile(atPath: fileURL.path()))
            }
        }
    }
}

fileprivate extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
            guard let attrs = try? attributesOfItem(atPath: path) else {
                return nil
            }

            return attrs[.size] as? Int64
    }
}
