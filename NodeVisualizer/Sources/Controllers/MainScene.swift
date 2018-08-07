//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


private enum StartingPositionType: UInt32 {
    case top = 0
    case bottom = 1
    case left = 2
    case right = 3

    static var allValues: [StartingPositionType] {
        return [.top, .bottom, .left, .right]
    }
}


class MainScene: SKScene, SKPhysicsContactDelegate {

    var gestureManager: GestureManager!
    private var nodeClusters = Set<NodeCluster>()
    private var lastUpdateTimeInterval: TimeInterval = 0

    private struct Constants {
        static let maximumUpdateDeltaTime: TimeInterval = 1.0 / 60.0
        static let slowGravity = CGVector(dx: 0.02, dy: -0.03)
        static let worldPadding: CGFloat = 100
    }


    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        setupGestures()
        addPhysics()
        addNodes()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        var deltaTime = currentTime - lastUpdateTimeInterval
        deltaTime = deltaTime > Constants.maximumUpdateDeltaTime ? Constants.maximumUpdateDeltaTime : deltaTime
        lastUpdateTimeInterval = currentTime

        EntityManager.instance.update(deltaTime)
        for cluster in nodeClusters {
            cluster.update(deltaTime)
        }
    }


    // MARK: SKPhysicsContactDelegate

    func didBegin(_ contact: SKPhysicsContact) {
        // whenever an entity comes into contact with a bounding node, set the contacted entity's hasCollidedWithBoundingNode to true
        if contact.bodyA.node?.name == "boundingNode",
            let contactEntity = contact.bodyB.node?.entity as? RecordEntity,
            !contactEntity.hasCollidedWithBoundingNode,
            contactEntity.state is SeekTappedEntityState {
            contactEntity.hasCollidedWithBoundingNode = true
        } else if let contactEntity = contact.bodyA.node?.entity as? RecordEntity,
            !contactEntity.hasCollidedWithBoundingNode,
            contactEntity.state is SeekTappedEntityState,
            contact.bodyB.node?.name == "boundingNode" {
            contactEntity.hasCollidedWithBoundingNode = true
        }
    }


    // MARK: Setup

    private func setupGestures() {
        guard let view = view else {
            return
        }

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: view)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.handleTapGesture(gesture)
        }

        let nsTapGesture = NSClickGestureRecognizer(target: self, action: #selector(handleSystemClickGesture(_:)))
        view.addGestureRecognizer(nsTapGesture)
    }

    private func addPhysics() {
        let origin = CGPoint(x: -Constants.worldPadding, y: -Constants.worldPadding)
        let size = CGSize(width: frame.width + Constants.worldPadding * 2, height: frame.height + Constants.worldPadding * 2)
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: origin, size: size))
        physicsWorld.gravity = Constants.slowGravity
        physicsWorld.contactDelegate = self
    }

    private func addNodes() {
        for entity in EntityManager.instance.allEntities() {
            entity.set(state: .falling)

            if let recordNode = entity.component(ofType: RenderComponent.self)?.recordNode {
                recordNode.position.x = randomX()
                recordNode.position.y = randomY()
                recordNode.zPosition = 1
                addChild(recordNode)
            }
        }
    }


    // MARK: Gesture Handlers

    private func handleTapGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position else {
            return
        }

        let nodePosition = convertPoint(fromView: position)

        guard let recordNode = nodes(at: nodePosition).first(where: { $0 is RecordNode }) as? RecordNode else {
            return
        }

        print("ID: \(recordNode.record.id)")

        switch tap.state {
        case .ended:
            select(recordNode)
        default:
            return
        }
    }

    @objc
    private func handleSystemClickGesture(_ recognizer: NSClickGestureRecognizer) {
        let clickPosition = recognizer.location(in: recognizer.view)
        let nodePosition = convertPoint(fromView: clickPosition)

        guard let recordNode = nodes(at: nodePosition).first(where: { $0 is RecordNode }) as? RecordNode else {
            return
        }

        print("ID: \(recordNode.record.id) \n Type: \(recordNode.record.type)")

        switch recognizer.state {
        case .ended:
            select(recordNode)
        default:
            return
        }
    }


    // MARK: Helpers

    /// Sets up all the data relationships for the tapped node and starts the physics interactions
    private func select(_ node: RecordNode) {
        guard let entityForNode = node.entity as? RecordEntity else {
            return
        }

        let cluster = nodeCluster(for: entityForNode)
        nodeClusters.insert(cluster)

        switch entityForNode.state {
        case is SeekTappedEntityState, is FallingState:
            cluster.select(entityForNode)
            entityForNode.set(state: .tapped)
        case is TappedState:
            cluster.reset()
            nodeClusters.remove(cluster)
        default:
            return
        }
    }

    private func nodeCluster(for entity: RecordEntity) -> NodeCluster {
        if let current = entity.cluster {
            return current
        }

        return NodeCluster(scene: self, entity: entity)
    }

    private func getRandomPosition() -> CGPoint {
        var point = CGPoint.zero

        guard let position = StartingPositionType(rawValue: arc4random_uniform(4)) else {
            return point
        }

        switch position {
        case .top:
            point = CGPoint(x: randomX(), y: size.height - style.nodePhysicsBodyRadius)
            return point
        case .bottom:
            point = CGPoint(x: randomX(), y: style.nodePhysicsBodyRadius)
            return point
        case .left:
            point = CGPoint(x: style.nodePhysicsBodyRadius, y: randomY())
            return point
        case .right:
            point = CGPoint(x: size.width - style.nodePhysicsBodyRadius, y: randomY())
            return point
        }
    }

    private func randomX() -> CGFloat {
        let lowestValue = Int(style.nodePhysicsBodyRadius)
        let highestValue = Int(size.width - style.nodePhysicsBodyRadius)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }

    private func randomY() -> CGFloat {
        let lowestValue = Int(style.nodePhysicsBodyRadius)
        let highestValue = Int(size.height - style.nodePhysicsBodyRadius)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }
}
