//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides a SKNode for a NodeBoundingEntity. This component is mainly responsible for updating the size of its SKNode's physicsBody and updating its maximum distance calculated from its level's entities.
class NodeBoundingRenderComponent: GKComponent {

    let cluster: NodeCluster

    /// The bounding entity's node
    var node: SKNode?

    /// The maximum distance between the root and the contactEntities for this bounding entity
    var maxRadius: CGFloat = Constants.initialRadius

    /// The minimum radius of its own responsible level's bounding node. It is the radius of the bounding node without considering its contactEntities
    var minRadius: CGFloat = Constants.initialRadius

    /// Provides a snapshot of `self` minimum radius
    var snapshot: CGFloat?

    /// The bounding node's level that the component is responsible for
    var level: Int!

    /// Local variable of the previous level's bounding node maxRadius. Used to determine its own level's bounding node maxRadius
    private var previousLevelMaxDistance: CGFloat = Constants.initialRadius

    private struct Constants {
        static let initialRadius: CGFloat = style.nodePhysicsBodyRadius + 5.0
        static let minimumOffset: CGFloat = style.nodePhysicsBodyRadius
        static let maximumOffset: CGFloat = style.nodePhysicsBodyRadius * 2
    }


    // MARK: Initializer

    init(cluster: NodeCluster) {
        self.cluster = cluster
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

        if cluster.selectedEntity.state == .panning {
            return
        }

        /*
         Overall behavior/responsibility for this component is as follows:
            - Each NodeBoundingRenderComponent is responsible for calculating the distance between the root (center) and its own level entities (i.e. contactEntities).
                - This calculated distance becomes the component's maxRadius
            - The component's level node updates its own size depending on the previous level bounding node's maxRadius
         */

        // Scale its own bounding node by using its previous level's bounding node maxRadius
        if let previousLevelNodeBoundingEntity = cluster.layerForLevel[level - 1], let currentNode = node {

            // Get the maxRadius of the previous level bounding node
            let previousLevelBoundingNodeMaxRadius = previousLevelNodeBoundingEntity.nodeBoundingRenderComponent.maxRadius
//            let updatedPhysicsBodyRadius = previousLevelBoundingNodeMaxRadius + Constants.maximumOffset

            let updatedPhysicsBodyRadius = snapshot ?? previousLevelBoundingNodeMaxRadius + Constants.maximumOffset

            // Set its maxRadius to the previous level bounding node's maxRadius so that the next level bounding node can scale to the correct size
            maxRadius = previousLevelBoundingNodeMaxRadius
            minRadius = updatedPhysicsBodyRadius
            previousLevelMaxDistance = previousLevelBoundingNodeMaxRadius

//            maxRadius = snapshot ?? previousLevelBoundingNodeMaxRadius


//            if let snapshotRadius = cluster.radiusSnapshotForLayerComponent[self] {
//                maxRadius = snapshotRadius
//            } else {
//                maxRadius = previousLevelBoundingNodeMaxRadius
//            }

            // Create new physicsBody based on the previous level bounding node's maxRadius. Scaling its own bounding node causes "stuck collisions" to its physicsBody
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

        var distance: CGFloat = 0.0
        if let contactEntities = cluster.entitiesForLevel.at(index: level) {
            // Iterate through its contactEntities to see if it hasCollidedWithBoundingNode, and determine the max distance from the root to the contactEntity
            for contactEntity in contactEntities where contactEntity.hasCollidedWithBoundingNode {
//                if cluster.radiusSnapshotForLayerComponent[self] != nil {
//                    cluster.radiusSnapshotForLayerComponent.removeValue(forKey: self)
//                }
                if snapshot != nil {
                    snapshot = nil
                }
                let calculatedRadius = cluster.distance(to: contactEntity) + Constants.minimumOffset
                if calculatedRadius > distance {
                    distance = calculatedRadius
                    maxRadius = distance
                }
            }
        }

        // Set the maxRadius for this level's bounding node
//        maxRadius = distance > previousLevelMaxDistance ? distance : previousLevelMaxDistance
    }
}
