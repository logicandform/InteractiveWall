//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that provides an 'SKNode' for an entity. This enables it to be represented in the SpriteKit world.
*/

import Foundation
import SpriteKit
import GameplayKit


class RenderComponent: GKComponent {

    private(set) var recordNode: RecordNode


    // MARK: Initializer

    init(record: TestingEnvironment.Record) {
        self.recordNode = RecordNode(record: record)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle
    
    override func didAddToEntity() {
        recordNode.entity = entity
    }

    override func willRemoveFromEntity() {
        recordNode.entity = nil
    }
}
