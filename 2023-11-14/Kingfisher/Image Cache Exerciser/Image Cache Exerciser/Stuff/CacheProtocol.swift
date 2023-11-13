//
// Created by Joey Jarosz on 10/9/23.
//

import Foundation

///
///
protocol CacheProtocol {
    func clear() async
    func preload(with urlPaths: [String])
    func configure(for cacheType: Cache.CacheType)
    func dumpStats(photoCount: Int?, imageSize: String?, toolkit: String?) -> [(String, String)]
}

/// Placeholder methods for use during development...
///
extension CacheProtocol {
    func clear() async {
        // nop
    }
    
    func preload(with urlPaths: [String]) {
        // nop
    }
    
    func configure(for cacheType: Cache.CacheType) {
        // nop
    }
    
    func dumpStats(photoCount: Int?, imageSize: String?, toolkit: String?) -> [(String, String)] {
        return [("", "")]
    }
}
