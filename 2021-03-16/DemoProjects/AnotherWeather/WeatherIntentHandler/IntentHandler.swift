//
// Created by Joey Jarosz on 3/13/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
//    func handle(intent: ConfigurationIntent, completion: @escaping (ConfigurationIntentResponse) -> Swift.Void) {
//        completion(
//    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        return self
    }
    
}
