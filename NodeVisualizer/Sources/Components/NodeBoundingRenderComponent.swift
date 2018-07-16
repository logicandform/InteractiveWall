//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingRenderComponent: GKComponent {

    /// The bounding entity's node
    var node: SKNode?

    /// The entities that is associated with this component's bounding node. maxRadius is determined by calculating max distance between root and these entities
//    var contactEntities: [RecordEntity]?

    /// The previous level's node bounding entity. Use its maxRadius to scale its own bounding node to the appropriate size
//    var previousNodeBoundingEntity: NodeBoundingEntity?

    /// The maximum distance between the root and the contactEntities for this bounding entity
    var maxRadius: CGFloat = 0.0

    /// Determines whether or not the next bounding node should update its radius
    var shouldScaleNode: Bool = true

    /// The node bounding level that the component is responsible for
    var level: Int!

    /// Local variable of the previous level's bounding node maxRadius. Used to determine its own level's bounding node maxRadius
    private var previousLevelMaxDistance: CGFloat = 0.0

    private struct Constants {
        static let minimumOffset: CGFloat = NodeConfiguration.Record.physicsBodyRadius
        static let maximumOffset: CGFloat = NodeConfiguration.Record.physicsBodyRadius * 2
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

        /*
         Overall behavior/responsibility for this component is as follows:
            - Each NodeBoundingRenderComponent is responsible for calculating the distance between the root (center) and its own level entities (i.e. contactEntities).
                - This calculated distance becomes the component's maxRadius
            - The component's level node updates its own size depending on the previous level bounding node's maxRadius
         */

        // scale its own bounding node by using its previous level's bounding node maxRadius
        if let previousLevelNodeBoundingEntity = NodeBoundingManager.instance.nodeBoundingEntityForLevel[level - 1], let currentNode = node {

            // get the maxRadius of the previous level bounding node
            let previousLevelBoundingNodeMaxRadius = previousLevelNodeBoundingEntity.nodeBoundingRenderComponent.maxRadius
            let updatedPhysicsBodyRadius = previousLevelBoundingNodeMaxRadius + Constants.maximumOffset

            // set its maxRadius to the previous level bounding node's maxRadius so that the next level bounding node can scale to the correct size
            maxRadius = previousLevelBoundingNodeMaxRadius
            previousLevelMaxDistance = previousLevelBoundingNodeMaxRadius

            // create new physicsBody based on the previous level bounding node's maxRadius. Scaling its own bounding node causes "stuck collisions" to its physicsBody
            let newPhysicsBody = SKPhysicsBody(circleOfRadius: updatedPhysicsBodyRadius)
            newPhysicsBody.categoryBitMask = currentNode.physicsBody!.categoryBitMask
            newPhysicsBody.contactTestBitMask = currentNode.physicsBody!.contactTestBitMask
            newPhysicsBody.collisionBitMask = currentNode.physicsBody!.collisionBitMask
            newPhysicsBody.isDynamic = false
            newPhysicsBody.restitution = 0
            newPhysicsBody.friction = 0

            currentNode.physicsBody = nil
            currentNode.physicsBody = newPhysicsBody
        }

        let contactEntities = EntityManager.instance.entitiesInLevel[level]
        var distance: CGFloat = 0.0

        // iterate through its contactEntities if it hasCollidedWithBoundingNode, and determine the max distance from the root to the contactEntity
        for contactEntity in contactEntities where contactEntity.hasCollidedWithBoundingNode {
            let calculatedRadius = NodeBoundingManager.instance.distance(to: contactEntity) + Constants.minimumOffset
            if calculatedRadius > distance {
                distance = calculatedRadius
            }
        }

        // set the maxRadius for this level's bounding node
        maxRadius = distance > previousLevelMaxDistance ? distance : previousLevelMaxDistance
    }
}
