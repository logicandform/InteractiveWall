//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var nodeGestureManager: NodeGestureManager!
    private var nodeClusters = Set<NodeCluster>()
    private var lastUpdateTimeInterval: TimeInterval = 0
    private var selectedEntity: RecordEntity?

    private struct Constants {
        static let maximumUpdateDeltaTime: TimeInterval = 1.0 / 60.0
        static let panningThreshold: CGFloat = 5
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

        for case let node as RecordNode in children {
            node.zRotation = 0
        }
    }


    // MARK: Setup

    private func setupGestures() {
        guard let view = view else {
            return
        }

        let nsTapGesture = NSClickGestureRecognizer(target: self, action: #selector(handleSystemClickGesture(_:)))
        view.addGestureRecognizer(nsTapGesture)

        let nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleSystemPanGesture(_:)))
        view.addGestureRecognizer(nsPanGesture)
    }

    private func addPhysics() {
        let origin = CGPoint(x: -Constants.worldPadding, y: -Constants.worldPadding)
        let size = CGSize(width: frame.width + Constants.worldPadding * 2, height: frame.height + Constants.worldPadding * 2)
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: origin, size: size))
        physicsWorld.gravity = .zero
    }

    private func addNodes() {
        for entity in EntityManager.instance.allEntities() {
            entity.set(state: .falling)

            if let recordNode = entity.component(ofType: RenderComponent.self)?.recordNode {
                recordNode.position.x = randomX()
                recordNode.position.y = randomY()
                recordNode.zPosition = 1
                addChild(recordNode)
                setupGestures(for: recordNode)
            }
        }
    }

    private func setupGestures(for node: SKNode) {
        let tapGesture = TapGestureRecognizer()
        nodeGestureManager.add(tapGesture, to: node)
        tapGesture.gestureUpdated = handleTapGesture(_:)

        let panGesture = PanGestureRecognizer()
        nodeGestureManager.add(panGesture, to: node)
        panGesture.gestureUpdated = handlePanGesture(_:)
    }


    // MARK: Gesture Handlers

    private func handleTapGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let recordNode = nodeGestureManager.node(for: tap) as? RecordNode else {
            return
        }

        switch tap.state {
        case .ended:
            select(recordNode)
        default:
            return
        }
    }

    private func handlePanGesture(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer,
            let node = nodeGestureManager.node(for: pan) as? RecordNode,
            let entity = node.entity as? RecordEntity,
            entity.state.pannable else {
            return
        }

        let deltaX = pan.delta.dx
        let deltaY = pan.delta.dy
        let newX = node.position.x + deltaX
        let newY = node.position.y + deltaY
        let position = CGPoint(x: newX, y: newY)

        switch pan.state {
        case .recognized:
            let distance = CGFloat(hypotf(Float(deltaX), Float(deltaY)))
            if distance <= Constants.panningThreshold {
                return
            }

            entity.set(state: .panning)
            entity.set(position: position)
            entity.cluster?.updateClusterPosition(to: position)
        case .momentum:
            if entity.state == .panning {
                entity.set(position: position)
                entity.cluster?.updateClusterPosition(to: position)
            }
        case .possible:
            if entity.state == .panning {
                if entity.cluster == nil {
                    entity.set(state: .falling)
                } else {
                    entity.set(state: .tapped)
                }
            }
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

        switch recognizer.state {
        case .ended:
            select(recordNode)
        default:
            return
        }
    }

    @objc
    private func handleSystemPanGesture(_ recognizer: NSPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            let pannedPosition = recognizer.location(in: recognizer.view)
            let pannedNodePosition = convertPoint(fromView: pannedPosition)
            if let recordNode = nodes(at: pannedNodePosition).first(where: { $0 is RecordNode }) as? RecordNode,
                let entity = recordNode.entity as? RecordEntity,
                entity.state.pannable {
                selectedEntity = entity
            }
        case .changed:
            let pannedPosition = recognizer.location(in: recognizer.view)
            let pannedNodePosition = convertPoint(fromView: pannedPosition)

            let pannedTranslation = recognizer.translation(in: recognizer.view)
            let nodePannedTranslation = convertPoint(fromView: pannedTranslation)
            let distance = CGFloat(hypotf(Float(nodePannedTranslation.x), Float(nodePannedTranslation.y)))
            if distance <= Constants.panningThreshold {
                return
            }

            selectedEntity?.set(state: .panning)
            selectedEntity?.set(position: pannedNodePosition)
            selectedEntity?.cluster?.updateClusterPosition(to: pannedNodePosition)
        case .ended:
            guard let selectedEntity = selectedEntity else {
                return
            }

            let pannedVelocity = recognizer.velocity(in: recognizer.view)
            let nodePannedVelocity = convertPoint(fromView: pannedVelocity)
            let delta = CGPoint(x: nodePannedVelocity.x * 0.4, y: nodePannedVelocity.y * 0.4)
            let currentPosition = selectedEntity.position
            let newPosition = CGPoint(x: currentPosition.x + delta.x, y: currentPosition.y + delta.y)

            selectedEntity.set(position: newPosition)
            selectedEntity.cluster?.updateClusterPosition(to: newPosition)

            if selectedEntity.state == .panning {
                if selectedEntity.cluster == nil {
                    selectedEntity.set(state: .falling)
                } else {
                    selectedEntity.set(state: .tapped)
                }

                self.selectedEntity = nil
            }
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
        case .seekEntity(_), .falling:
            cluster.select(entityForNode)
        case .tapped:
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
