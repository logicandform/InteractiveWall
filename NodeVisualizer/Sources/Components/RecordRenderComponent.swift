//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides an 'SKNode' for an entity. This enables it to be represented in the SpriteKit world.
class RecordRenderComponent: GKComponent {

    private(set) var recordNode: RecordNode
    private let record: RecordDisplayable


    // MARK: Initializer

    init(record: RecordDisplayable) {
        self.record = record
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

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard let entity = entity as? RecordEntity, let currentLevel = entity.clusterLevel.currentLevel else {
            return
        }

        var targetRadius: CGFloat
        switch currentLevel {
        case -1:
            targetRadius = 45
        case 0:
            targetRadius = 40
        case 1:
            targetRadius = 30
        case 2:
            targetRadius = 25
        case 3:
            targetRadius = 20
        case 4:
            targetRadius = 15
        case 5:
            targetRadius = 10
        default:
            targetRadius = 20
        }

        let currentWidth = recordNode.calculateAccumulatedFrame().width / 2
        let currentHeight = recordNode.calculateAccumulatedFrame().height / 2
        let hypot = CGFloat(hypotf(Float(currentWidth), Float(currentHeight)))
        var currentRadius = hypot

        let difference = abs(targetRadius - currentRadius)
        let sqrtDiff = CGFloat(sqrt(Float(difference)))
        currentRadius += targetRadius > currentRadius ? sqrtDiff : -sqrtDiff

        let updatedRecordNode = RecordNode(record: record, ofSize: currentRadius)
        updatedRecordNode.position = recordNode.position
        recordNode = updatedRecordNode

        let updatedPhysicsBody = SKPhysicsBody(circleOfRadius: currentRadius)
        let currentPhysicsBody = entity.physicsBody
        updatedPhysicsBody.categoryBitMask = currentPhysicsBody.categoryBitMask
        updatedPhysicsBody.collisionBitMask = currentPhysicsBody.collisionBitMask
        updatedPhysicsBody.contactTestBitMask = currentPhysicsBody.contactTestBitMask
        updatedPhysicsBody.restitution = currentPhysicsBody.restitution
        updatedPhysicsBody.friction = currentPhysicsBody.friction
//        updatedPhysicsBody.isDynamic = currentPhysicsBody.isDynamic

        entity.physicsComponent.physicsBody = updatedPhysicsBody
        recordNode.physicsBody = entity.physicsComponent.physicsBody
    }
}
