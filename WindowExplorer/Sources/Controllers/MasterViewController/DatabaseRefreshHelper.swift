//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class DatabaseRefreshHelper {


    static func refreshDatabase(completion: @escaping (DatabaseStatus) -> Void) {
        firstly {
            try CachingNetwork.refresh()
        }.then { response in
            completion(response)
        }.catch { error in
            let response = DatabaseStatus(refreshing: false, error: true, description: "Refresh Database Error: \(error.localizedDescription)")
            completion(response)
        }
    }

    static func getRefreshStatus(completion: @escaping (DatabaseStatus) -> Void) {
        firstly {
            try CachingNetwork.status()
        }.then { status in
            completion(status)
        }.catch { error in
            let status = DatabaseStatus(refreshing: false, error: true, description: "Database Error: \(error.localizedDescription)")
            completion(status)
        }
    }
}
