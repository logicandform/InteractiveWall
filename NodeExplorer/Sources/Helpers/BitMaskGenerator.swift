//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit


final class BitMaskGenerator {

    private struct Constants {
        static let availableClusterBits = 31
        static let backgroundBitMask: UInt32 = 1 << 31
    }

    static func bitMask(for entity: RecordEntity) -> UInt32 {
        switch entity.state {
        case .drift:
            return Constants.backgroundBitMask
        case .dragging:
            if let cluster = entity.cluster {
                return 1 << inset(for: cluster)
            } else {
                return Constants.backgroundBitMask
            }
        case .seekEntity:
            if let cluster = entity.cluster {
                if cluster.selectedEntity.state == .dragging {
                    return 1 << inset(for: cluster)
                } else if let level = entity.clusterLevel.currentLevel {
                    let levelMask: UInt32 = 1 << level
                    return levelMask << inset(for: cluster)
                }
            }
        default:
            return .min
        }

        return .min
    }

    static func bitMask(for layer: ClusterLayerNode) -> UInt32 {
        let levelMask: UInt32 = 1 << layer.level
        return levelMask << inset(for: layer.cluster)
    }


    // MARK: Helpers

    // Returns the inset for a cluster for a UInt32 bit mask, leaving space for the background mask
    private static func inset(for cluster: NodeCluster) -> Int {
        let normalizedID = cluster.id % (Constants.availableClusterBits / NodeCluster.maxRelatedLevels)
        return normalizedID * NodeCluster.maxRelatedLevels
    }
}
