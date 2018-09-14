//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import Alamofire
import AlamofireImage


class ClusterLayerNode: SKSpriteNode {
    static let nodeName = "boundingNode"

    private let level: Int

    private struct Constants {
        static let layerNodeImage = "layer-node"
    }


    // MARK: Initializers

    init(level: Int, radius: CGFloat, center: CGPoint) {
        self.level = level
        super.init(texture: nil, color: .clear, size: CGSize(width: radius*2, height: radius*2))
        texture = SKTexture(imageNamed: Constants.layerNodeImage)
        let alpha = 1 - CGFloat(level) * 0.18
        color = NSColor(white: 0.2, alpha: alpha)
        colorBlendFactor = 1
        position = center
        zPosition = CGFloat(-level)
        name = ClusterLayerNode.nodeName
        physicsBody = ClusterLayerNode.physicsBody(radius: radius)
        let bitMasks = ColliderType.layerNodeBitMasks(forLevel: level)
        set(bitMasks)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func set(_ bitMasks: ColliderType) {
        physicsBody?.categoryBitMask = bitMasks.categoryBitMask
        physicsBody?.collisionBitMask = bitMasks.collisionBitMask
        physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask
    }

    // Updates the size of the physics body and node
    func set(radius: CGFloat) {
        physicsBody = ClusterLayerNode.physicsBody(radius: radius)
        let bitMasksForLevel = ColliderType.layerNodeBitMasks(forLevel: level)
        set(bitMasksForLevel)
        size = CGSize(width: radius*2, height: radius*2)
    }

    static func physicsBody(radius: CGFloat) -> SKPhysicsBody {
        let physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody.mass = style.defaultBodyMass
        physicsBody.isDynamic = false
        physicsBody.restitution = 0
        physicsBody.friction = 1
        return physicsBody
    }
}
