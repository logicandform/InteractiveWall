//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


protocol NodeBoundingRenderComponentDelegate: class {
    func changeInRadiusNotification(withRadius radius: CGFloat)
}

class NodeBoundingRenderComponent: GKComponent {

    var node: SKNode?
    weak var delegate: NodeBoundingRenderComponentDelegate?

    /// the entities that this bounding node should calculate the maxRadius with
    var contactEntities: [RecordEntity]?

    /// the previous level's node bounding entity. Use its maxRadius to scale its own bounding level node to the appropriate size
    var previousNodeBoundingEntity: NodeBoundingEntity?

    /// the maximum distance between the center of screen and the contactEntities for this bounding node
    var maxRadius: CGFloat = 0.0

    /// to tell whether or not the next bounding node should update its radius
    var shouldScaleNode: Bool = false


    private var previousCalculatedDistanceToFurthestEntity: CGFloat = 0.0

    private struct Constants {
        static let offset: CGFloat = NodeConfiguration.Record.physicsBodyRadius + 15.0
    }


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

        guard let contactEntities = contactEntities else {
            return
        }


        if let previousLevelNodeBoundingEntity = previousNodeBoundingEntity, let currentNode = node, previousLevelNodeBoundingEntity.nodeBoundingRenderComponent.shouldScaleNode {

            let previousLevelBoundingNodeMaxRadius = previousLevelNodeBoundingEntity.nodeBoundingRenderComponent.maxRadius + 40

            let currentNodeRadiusWidth = currentNode.frame.width / 2
            let currentNodeRadiusHeight = currentNode.frame.height / 2
            let currentRadius = currentNodeRadiusWidth > currentNodeRadiusHeight ? currentNodeRadiusWidth : currentNodeRadiusHeight

            maxRadius = previousLevelBoundingNodeMaxRadius
            shouldScaleNode = true

//            let scale = previousLevelBoundingNodeMaxRadius / currentRadius
//            let scaleAction = SKAction.scale(by: scale, duration: 0)
//            currentNode.run(scaleAction)

            let newPhysicsBody = SKPhysicsBody(circleOfRadius: previousLevelBoundingNodeMaxRadius)
            newPhysicsBody.categoryBitMask = currentNode.physicsBody!.categoryBitMask
            newPhysicsBody.contactTestBitMask = currentNode.physicsBody!.contactTestBitMask
            newPhysicsBody.collisionBitMask = currentNode.physicsBody!.collisionBitMask
            newPhysicsBody.isDynamic = false
            newPhysicsBody.restitution = 0
            newPhysicsBody.friction = 0

            currentNode.physicsBody = nil
            currentNode.physicsBody = newPhysicsBody

        }


        for contactEntity in contactEntities where contactEntity.hasCollidedWithBoundingNode {
            let calculatedRadius = NodeBoundingManager.instance.distance(to: contactEntity) + 15.0 // use minimum radius to the edge of the contactEntity

            let difference = calculatedRadius - previousCalculatedDistanceToFurthestEntity
            let absoluteDifference = difference.magnitude

            // keep track of the absolute value difference between the currentMax and the new calculatedMax. If difference is great enough, then "notify"
//            if absoluteDifference >= 30.0 {
                maxRadius = calculatedRadius
                previousCalculatedDistanceToFurthestEntity = calculatedRadius
                shouldScaleNode = true
//            } else {
//                shouldScaleNode = false
//            }
        }





    }
}
