//
// Created by Joey Jarosz on 11/12/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import WatchConnectivity

/// This class is responsible for communication to the matching phone app...
/// 
class CommsWatch : NSObject, WCSessionDelegate {
    var session: WCSession

    init(session: WCSession = .default) {
        self.session = session

        super.init()
        
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("Error: \(error)")
        }
    }
    
    func send(_ text: String) {
        guard session.activationState == .activated else {
            print("OOPS")
            return
        }
        
        let message = ["Selection": text]
        
        session.sendMessage(message) { reply in
            print("Reply: \(reply)")
        } errorHandler: { error in
            print("Error: \(error)")
        }
    }
}
