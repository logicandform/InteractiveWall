//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class PhysicsComponent: GKComponent {
    typealias CategoryBitMask = UInt32

    var physicsBody: SKPhysicsBody


    init(physicsBody: SKPhysicsBody) {
        self.physicsBody = physicsBody
        super.init()
        setupInitialPhysicsBodyProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func setCategoryBitMask(bitmask: CategoryBitMask) {
        physicsBody.categoryBitMask = bitmask
    }

    func setFieldBitMask(bitmask: CategoryBitMask) {
        physicsBody.fieldBitMask = bitmask
    }


    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
    }

}





