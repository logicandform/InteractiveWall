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


    init(record: TestingEnvironment.Record) {
        self.recordNode = RecordNode(record: record)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func didAddToEntity() {
        recordNode.entity = entity
    }

    override func willRemoveFromEntity() {
        recordNode.entity = nil
    }


    func boundingDiameterNode(forRadius radius: CGFloat) -> SKNode? {
        guard let scene = recordNode.scene as? MainScene else {
            return nil
        }

        let boundingNode = SKShapeNode(circleOfRadius: radius)
        boundingNode.position = recordNode.position
        boundingNode.isHidden = true

        boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        boundingNode.physicsBody?.categoryBitMask = 0x1 << 1
        boundingNode.physicsBody?.contactTestBitMask = 0x1 << 1
        boundingNode.physicsBody?.collisionBitMask = 0x1 << 1
        boundingNode.physicsBody?.isDynamic = false

        boundingNodes.insert(boundingNode)
        scene.addChild(boundingNode)

        return boundingNode
    }








}
