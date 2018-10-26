//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import Alamofire
import AlamofireImage


class ClusterLayerNode: SKSpriteNode {
    static let nodeName = "boundingNode"

    let level: Int
    unowned var cluster: NodeCluster

    private struct Constants {
        static let layerNodeImage = "layer_node"
    }


    // MARK: Initializers

    init(level: Int, cluster: NodeCluster, radius: CGFloat, center: CGPoint) {
        self.level = level
        self.cluster = cluster
        super.init(texture: nil, color: .clear, size: CGSize(width: radius*2, height: radius*2))
        texture = SKTexture(imageNamed: Constants.layerNodeImage)
        let alpha = 0.8 - CGFloat(level) * 0.18
        color = NSColor(white: 0.2, alpha: alpha)
        colorBlendFactor = 1
        position = center
        name = ClusterLayerNode.nodeName
        physicsBody = ClusterLayerNode.physicsBody(radius: radius)
        updateBitMask()
        updateZPosition()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    // Updates the size of the physics body and node
    func set(radius: CGFloat) {
        physicsBody = ClusterLayerNode.physicsBody(radius: radius)
        size = CGSize(width: radius*2, height: radius*2)
        updateBitMask()
    }

    static func physicsBody(radius: CGFloat) -> SKPhysicsBody {
        let physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody.mass = style.nodePhysicsBodyMass
        physicsBody.isDynamic = false
        physicsBody.restitution = 0
        physicsBody.friction = 1
        return physicsBody
    }


    // MARK: Setup

    private func updateBitMask() {
        let mask = BitMaskGenerator.bitMask(for: self)
        physicsBody?.categoryBitMask = mask
        physicsBody?.collisionBitMask = mask
        physicsBody?.contactTestBitMask = mask
    }

    private func updateZPosition() {
        let clusterOffset = (cluster.id + 1) * 10
        let layerOffset = 5
        zPosition = CGFloat(clusterOffset - (level + layerOffset))
    }
}
