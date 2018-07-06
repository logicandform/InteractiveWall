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

    var boundingNodes = Set<SKNode>()

    private struct BoundingNodeBitMasks {
        let categoryBitMask: UInt32
        let contactTestBitMask: UInt32
        let collisionBitMask: UInt32
    }


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


    // MARK: API

    func boundingDiameterNode(forRadius radius: CGFloat, level: Int) -> SKNode? {
        guard let scene = recordNode.scene as? MainScene else {
            return nil
        }

        let boundingNode = SKShapeNode(circleOfRadius: radius)
        boundingNode.position = recordNode.position
        boundingNode.isHidden = true

        boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        boundingNode.physicsBody?.isDynamic = false

        let bitMasks = boundingNodeBitMasks(forLevel: level)
        boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
        boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask
        boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask

        boundingNodes.insert(boundingNode)
        scene.addChild(boundingNode)

        return boundingNode
    }


    // MARK: Helpers

    private func boundingNodeBitMasks(forLevel level: Int) -> BoundingNodeBitMasks {
        let categoryBitMask: UInt32 = 0x1 << level
        let contactTestBitMask: UInt32 = 0x1 << level
        let collisionBitMask: UInt32 = 0x1 << level

        return BoundingNodeBitMasks(
            categoryBitMask: categoryBitMask,
            contactTestBitMask: contactTestBitMask,
            collisionBitMask: collisionBitMask
        )
    }
}
