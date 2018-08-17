//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingEntity: GKEntity {

    var nodeBoundingRenderComponent: NodeBoundingRenderComponent {
        guard let renderComponent = component(ofType: NodeBoundingRenderComponent.self) else {
            fatalError("A NodeBoundingEntity must have a NodeBoundingRenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    init(cluster: NodeCluster) {
        super.init()

        let renderComponent = NodeBoundingRenderComponent(cluster: cluster)
        addComponent(renderComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func setBitMasks(forLevel level: Int) {
        guard let physicsBody = nodeBoundingRenderComponent.node?.physicsBody else {
            return
        }

        physicsBody.categoryBitMask = 1 << level
        physicsBody.collisionBitMask = 1 << level
        physicsBody.contactTestBitMask = 1 << level
    }

    func setToOutMostBitMasks() {
        guard let physicsBody = nodeBoundingRenderComponent.node?.physicsBody else {
            return
        }

        physicsBody.categoryBitMask = ColliderType.outmostBoundingNode
        physicsBody.collisionBitMask = ColliderType.outmostBoundingNode
        physicsBody.contactTestBitMask = ColliderType.outmostBoundingNode
    }
}
