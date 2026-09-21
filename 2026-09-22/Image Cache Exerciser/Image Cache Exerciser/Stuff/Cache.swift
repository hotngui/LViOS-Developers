//
// Created by Joey Jarosz on 9/22/23.
//
//

import Foundation

/// A thin facade over the `URLCache` that backs the app's `AsyncImage` views. Clearing and
/// disk-usage reporting are delegated to `AsyncImageCacheController`; preloading pumps the
/// image URLs through the same `URLSession` the viewer uses so responses land in the shared
/// cache.
@MainActor
final class Cache {
    static let `default` = Cache()

    let controller = AsyncImageCacheController(cache: ImageNetworking.imageCache,
                                               cacheDirectory: ImageNetworking.cacheDirectory)

    private init() {
        // nop
    }

    func clear() async {
        controller.clearCache()
    }

    func preload(with urlPaths: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for path in urlPaths {
                guard let url = URL(string: path) else { continue }

                group.addTask {
                    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
                    _ = try? await ImageNetworking.imageSession.data(for: request)
                }
            }
        }
    }

    func dumpStats(photoCount: Int? = nil, imageSize: String? = nil, requestMode: ImageRequestMode? = nil) -> [(String, String)] {
        let formatter = ByteCountFormatter()
        let urlCache = ImageNetworking.imageCache

        controller.refreshDiskUsage()

        let totalMemory = formatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))
        let appUsedMemory = formatter.string(fromByteCount: Int64(usedMemory()))
        let diskUsed = formatter.string(fromByteCount: usedDisk(for: ImageNetworking.cacheDirectory))

        return [
            ("Cache:", "AsyncImage + URLCache"),
            ("Request Mode:", requestMode?.title ?? "-"),
            ("Photo Count:", "\(photoCount ?? -1)"),
            ("Image Size:", "\(imageSize ?? "")"),
            ("", ""),
            ("Device", ""),
            ("Total System Memory:", totalMemory),
            ("App Used Memory:", appUsedMemory),
            ("App Used Disk:", diskUsed),
            ("", ""),
            ("URLCache", ""),
            ("Memory Used:", formatter.string(fromByteCount: Int64(urlCache.currentMemoryUsage))),
            ("Memory Capacity:", formatter.string(fromByteCount: Int64(urlCache.memoryCapacity))),
            ("Disk Used:", controller.formattedDiskUsage),
            ("Disk Capacity:", controller.formattedDiskCapacity),
            ("Directory:", ImageNetworking.cacheDirectory.lastPathComponent)
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
