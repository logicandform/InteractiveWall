//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Persistence {

    static let instance = Persistence()


    private(set) var recordsForType = [RecordType: [RecordDisplayable]]()



    // Use singleton instance
    private init() {}


    // MARK: API

    func save(_ records: [RecordDisplayable]?, for type: RecordType) {

    }



    // MARK: Helpers





}





