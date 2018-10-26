//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit


final class BitMaskGenerator {

    static func bitMask(for entity: RecordEntity) -> UInt32 {
        guard let cluster = entity.cluster else {
            return .min
        }

        let clusterInset = inset(for: cluster)

        switch entity.state {
        case .dragging:
            return 1 << clusterInset
        case .seekEntity(_) where cluster.selectedEntity.state == .dragging:
            return 1 << clusterInset
        case .seekEntity(_) where entity.clusterLevel.currentLevel != nil:
            let levelMask: UInt32 = 1 << entity.clusterLevel.currentLevel!
            return levelMask << clusterInset
        default:
            return .min
        }
    }

    static func bitMask(for layer: ClusterLayerNode) -> UInt32 {
        let levelMask: UInt32 = 1 << layer.level
        let clusterInset = inset(for: layer.cluster)
        return levelMask << clusterInset
    }


    // MARK: Helpers

    // Returns the inset for a cluster for a UInt32 bit mask
    private static func inset(for cluster: NodeCluster) -> Int {
        let normalizedID = (cluster.id - 1) % (32 / NodeCluster.maxRelatedLevels)
        return normalizedID * NodeCluster.maxRelatedLevels
    }
}
