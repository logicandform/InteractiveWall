//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides a SKNode for a NodeBoundingEntity. This component is mainly responsible for updating the size of its SKNode's physicsBody and updating its maximum distance calculated from its level's entities.
class LayerRenderComponent: GKComponent {

    let level: Int
    unowned var cluster: NodeCluster
    let layerNode: ClusterLayerNode
    var minRadius: CGFloat
    var maxRadius: CGFloat
    private var currentRadius: CGFloat

    private struct Constants {
        static let entityDistanceOffset: CGFloat = 15
        static let defaultRadius: CGFloat = 1
    }


    // MARK: Initializer

    init(level: Int, radius: CGFloat?, cluster: NodeCluster, center: CGPoint) {
        let radius = radius ?? Constants.defaultRadius
        self.level = level
        self.cluster = cluster
        self.minRadius = radius
        self.maxRadius = radius
        self.currentRadius = radius
        self.layerNode = ClusterLayerNode(level: level, cluster: cluster, radius: radius, center: center)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        if cluster.selectedEntity.state == .dragging {
            return
        }

        /*
         Overall behavior/responsibility for this component is as follows:
            - Each LayerRenderComponent is responsible for calculating the distance between the root (center) and its own level entities (i.e. contactEntities).
                - This calculated distance becomes the component's maxRadius
            - The component's level node updates its own size depending on the previous level bounding node's maxRadius
         */

        // Calculate the distance between the center and its own level entities
        var distance: CGFloat = 0
        if let contactEntities = cluster.entitiesForLevel.at(index: level) {
            // Iterate through its contactEntities to see if it hasCollidedWithLayer, and determine the max distance from the root to the contactEntity
            for contactEntity in contactEntities {
                // Only use entities that have reached the layer and are not currently being dragged
                if case .seekEntity(_) = contactEntity.state, contactEntity.hasCollidedWithLayer {
                    let contactEntityRadiusOffset = contactEntity.bodyRadius + Constants.entityDistanceOffset
                    let calculatedRadius = cluster.distance(to: contactEntity) + contactEntityRadiusOffset
                    if calculatedRadius > distance {
                        distance = calculatedRadius
                    }
                }
            }
        }

        // Set the maxRadius for this level's bounding node
        maxRadius = max(distance, currentRadius)

        // Scale its own bounding node by using its previous level's bounding node maxRadius
        if let previousLevelNodeBoundingEntity = cluster.layerForLevel[level - 1] {
            let previousLevelBoundingNodeRadius = previousLevelNodeBoundingEntity.renderComponent.maxRadius
            let difference = abs(previousLevelBoundingNodeRadius - currentRadius)
            let sqrtDiff = CGFloat(sqrt(Float(difference)))
            currentRadius += previousLevelBoundingNodeRadius > currentRadius ? sqrtDiff : -sqrtDiff
            minRadius = currentRadius
            layerNode.set(radius: currentRadius)
        } else {
            let radius = cluster.selectedEntity.node.size.width/2
            currentRadius = radius
            minRadius = radius
            layerNode.set(radius: radius)
        }
    }
}
