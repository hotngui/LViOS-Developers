//
// Created by Joey Jarosz on 11/12/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import WatchConnectivity

/// This class is responsible for communication to the matching watch app...
///
class CommsPhone : NSObject, WCSessionDelegate, ObservableObject {
    var session: WCSession
    @Published var messageText: String?
    
    // MARK: -  Object Lifecycle
    
    init(session: WCSession = .default) {
        self.session = session

        super.init()
        
        session.delegate = self
        session.activate()
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("Error: \(error)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // nop
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // nop
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        messageText = message["Selection"] as? String
        UserDefaults.standard.setValue(messageText, forKeyPath: "Selection")
    }
}
