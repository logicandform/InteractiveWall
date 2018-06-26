//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/*
    Abstract:
    A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
*/

class PhysicsComponent: GKComponent {
    typealias CategoryBitMask = Int

    var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A PhysicsComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }


    var physicsBody: SKPhysicsBody

    private struct Constants {
        static let resetBitMask: UInt32 = 0
    }


    init(physicsBody: SKPhysicsBody) {
        self.physicsBody = physicsBody
        super.init()
        setupInitialPhysicsBodyProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func setCategoryBitMask(bitmask: CategoryBitMask) {
        physicsBody.categoryBitMask = UInt32(bitmask)
    }

    func setFieldBitMask(bitmask: CategoryBitMask) {
        physicsBody.fieldBitMask = UInt32(bitmask)
    }

    func reset() {
        physicsBody.fieldBitMask = Constants.resetBitMask
    }

    func createRadialGravityFieldNode() {
        let radialField = SKFieldNode.radialGravityField()
        radialField.strength = 5
        radialField.falloff = 1
        radialField.categoryBitMask = UInt32(1 << renderComponent.recordNode.record.id)
        renderComponent.recordNode.addChild(radialField)
    }

    func createDragFieldNode() {
        let dragField = SKFieldNode.dragField()
        dragField.strength = 1
        dragField.categoryBitMask = 0x1 << 1
        renderComponent.recordNode.addChild(dragField)
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 1
        physicsBody.restitution = 0
        physicsBody.linearDamping = 1
        physicsBody.mass = NodeConfiguration.Record.physicsBodyMass
        physicsBody.fieldBitMask = 0x1 << 0
    }
}
