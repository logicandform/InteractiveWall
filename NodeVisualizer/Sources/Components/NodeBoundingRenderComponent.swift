//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingRenderComponent: GKComponent {

    var node: SKNode?

    var contactEntities: [RecordEntity]?
    var contactEntitiesBoundingEntity: NodeBoundingEntity?


    // MARK: Initializer

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func didAddToEntity() {
        node?.entity = entity
    }

    override func willRemoveFromEntity() {
        node?.entity = nil
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // check the distance between the center root seek node and the contactEntities, and then scale the contactEntitiesBoundingEntity appropriately
        // when scaling the contactEntitiesBoundingEntity, also need to scale all of its descendant's contactEntitiesBoundingEntity (recursive)

    }


}











