//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingRenderComponent: GKComponent {

    var node: SKNode?

    var contactEntities: [RecordEntity]?
    var previousNodeBoundingEntity: NodeBoundingEntity?

    var needsUpdateFromLowerLevel = false
    var maxRadius: CGFloat = 0.0


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

        // find the max distance between the center and the contactEntities (only considering the entities that hasCollidedWithBoundingNode)
        // store the max distance to a variable
        // update its own bounding node size depending on the previous contactBoundingEntityNode







        // check the distance between the center root seek node and the contactEntities, and then scale the contactEntitiesBoundingEntity appropriately
        // when scaling the contactEntitiesBoundingEntity, also need to scale all of its descendant's contactEntitiesBoundingEntity (recursive)

        guard !needsUpdateFromLowerLevel else {
            // scale the size of the boundingEntity by lower level factor, then set the needsUpdateFromLowerLevel flag to false
            return
        }

        guard let contactEntities = contactEntities else {
            return
        }

        var calculatedRadius: CGFloat = 0.0

        for case let contactEntity in contactEntities where contactEntity.hasCollidedWithBoundingNode {
            let radius = NodeBoundingManager.instance.distance(to: contactEntity)
            if radius > calculatedRadius {
                calculatedRadius = radius
            }
        }

        // only perform scale if the radius that you calculate is greater than maxRadius, and update maxRadius to the new max
        if calculatedRadius > maxRadius {
            maxRadius = calculatedRadius

            if let boundingEntity = previousNodeBoundingEntity, let boundingEntityNode = boundingEntity.nodeBoundingRenderComponent.node {
                let currentRadiusSize = boundingEntityNode.calculateAccumulatedFrame().height / 2
                let scale = (calculatedRadius / currentRadiusSize) * (NodeConfiguration.Record.physicsBodyRadius * 2)

                let scaleAction = SKAction.scale(by: scale, duration: 0.5)
                boundingEntityNode.run(scaleAction)

                // also need to scale the higher levels (update needsUpdateFromLowerLevel flag for the higher levels)



            }



        }

        // could have a flag that turns true only when the scaling has finished for this update. This is so that scale calculations don't happen every single frame since we are doing this inside the update(deltaTime:) method


        // later we can do a time interval check to update the maxRadius property by going through all contacted entities and finding the maximum

    }




}











