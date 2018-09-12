//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit


struct ColliderType {
    static let staticNode: UInt32 = 0x00000000
    static let panLayerNode: UInt32 = 1 << 20
    static let clonedRecordNode: UInt32 = 1 << 21
    static let selectedRecordNode: UInt32 = 1 << 22

    let categoryBitMask: UInt32
    let collisionBitMask: UInt32
    let contactTestBitMask: UInt32


    // MARK: API

    static func defaultBitMasks() -> ColliderType {
        return ColliderType(categoryBitMask: 0xFFFFFFFF, collisionBitMask: 0xFFFFFFFF, contactTestBitMask: 0x00000000)
    }

    static func bitMasksForSelectedEntity() -> ColliderType {
        return ColliderType(categoryBitMask: ColliderType.selectedRecordNode, collisionBitMask: ColliderType.selectedRecordNode, contactTestBitMask: ColliderType.selectedRecordNode)
    }

    static func bitMasksForPanningLayer() -> ColliderType {
        return ColliderType(categoryBitMask: ColliderType.panLayerNode, collisionBitMask: ColliderType.panLayerNode, contactTestBitMask: ColliderType.panLayerNode)
    }

    static func resetBitMasks() -> ColliderType {
        return ColliderType(categoryBitMask: ColliderType.staticNode, collisionBitMask: ColliderType.staticNode, contactTestBitMask: ColliderType.staticNode)
    }

    static func bitMasksForClonedEntity() -> ColliderType {
        return ColliderType(categoryBitMask: ColliderType.clonedRecordNode, collisionBitMask: ColliderType.clonedRecordNode, contactTestBitMask: ColliderType.clonedRecordNode)
    }

    static func recordNodeBitMasks(forLevel level: Int) -> ColliderType {
        let categoryBitMask: UInt32 = 1 << level
        let collisionBitMask: UInt32 = 1 << level
        let contactTestBitMask: UInt32 = 1 << level

        return ColliderType(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }

    static func layerNodeBitMasks(forLevel level: Int) -> ColliderType {
        let levelBit = 10 + level
        let categoryBitMask: UInt32 = 1 << levelBit
        let contactTestBitMask: UInt32 = 1 << levelBit
        let collisionBitMask: UInt32 = 1 << levelBit

        return ColliderType(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }

    static func draggingBitMasks(for entity: RecordEntity) -> ColliderType {
        guard let level = entity.clusterLevel.currentLevel,
            let layerNodePhysicsBody = entity.cluster?.layerForLevel[0]?.renderComponent.layerNode.physicsBody else {
                return ColliderType.defaultBitMasks()
        }

        let levelBitMasks = ColliderType.recordNodeBitMasks(forLevel: level)
        let categoryBitMask = levelBitMasks.categoryBitMask | layerNodePhysicsBody.categoryBitMask
        let collisionBitMask = levelBitMasks.collisionBitMask | layerNodePhysicsBody.collisionBitMask
        let contactTestBitMask = levelBitMasks.contactTestBitMask | layerNodePhysicsBody.contactTestBitMask
        return ColliderType(categoryBitMask: categoryBitMask, collisionBitMask: collisionBitMask, contactTestBitMask: contactTestBitMask)
    }

    static func bitMasksForSeekingEntity(entity: RecordEntity) -> ColliderType {
        guard let level = entity.clusterLevel.currentLevel,
            let layerNodePhysicsBody = entity.cluster?.layerForLevel[level]?.renderComponent.layerNode.physicsBody else {
                return ColliderType.defaultBitMasks()
        }

        let levelBitMasks = ColliderType.recordNodeBitMasks(forLevel: level)
        let categoryBitMask = levelBitMasks.categoryBitMask | layerNodePhysicsBody.categoryBitMask
        let collisionBitMask = levelBitMasks.collisionBitMask | layerNodePhysicsBody.collisionBitMask
        let contactTestBitMask = levelBitMasks.contactTestBitMask | layerNodePhysicsBody.contactTestBitMask
        return ColliderType(categoryBitMask: categoryBitMask, collisionBitMask: collisionBitMask, contactTestBitMask: contactTestBitMask)
    }
}
