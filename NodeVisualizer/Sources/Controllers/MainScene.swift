//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var records: [TestingEnvironment.Record]!
    var gestureManager: GestureManager!

    private var entityManager = EntityManager()
    private var lastUpdateTimeInterval: TimeInterval = 0
    private var agentToSeek: GKAgent2D!

    private enum StartingPositionType: UInt32 {
        case top = 0
        case bottom = 1
        case left = 2
        case right = 3

        static var allValues: [StartingPositionType] {
            return [.top, .bottom, .left, .right]
        }
    }


    // MARK: Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)

        addGestures(to: view)
        setupSystemGesturesForTest(to: view)

        addPhysicsToScene()
        addRecordNodesToScene()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        let deltaTime = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime
        entityManager.update(deltaTime)

        for case let node as RecordNode in children {
            node.zRotation = 0
        }
    }


    // MARK: Setup

    private func addGestures(to view: SKView) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: view)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.handleTapGesture(gesture)
        }
    }

    private func setupSystemGesturesForTest(to view: SKView) {
        let tapGesture = NSClickGestureRecognizer(target: self, action: #selector(handleSystemClickGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    private func addPhysicsToScene() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero

        createRepulsiveField()

//        for type in StartingPositionType.allValues {
//            addLinearGravityField(to: type)
//        }
    }

    private func addRecordNodesToScene() {
        records.enumerated().forEach { index, record in
            let recordEntity = RecordEntity(record: record, manager: entityManager)

            recordEntity.intelligenceComponent.enterInitialState()

            if let recordNode = recordEntity.component(ofType: RenderComponent.self)?.recordNode {
                recordNode.position.x = randomX()
                recordNode.position.y = randomY()
                recordNode.zPosition = 1
//                recordEntity.updateAgentPositionToMatchNodePosition()

                let screenBoundsConstraint = SKConstraint.positionX(SKRange(lowerLimit: 0, upperLimit: frame.width), y: SKRange(lowerLimit: 0, upperLimit: frame.height))
                recordNode.constraints = [screenBoundsConstraint]

                entityManager.add(recordEntity)
                addChild(recordNode)

//                let destinationPosition = getRandomPosition()
//                let forceVector = CGVector(dx: destinationPosition.x - recordNode.position.x, dy: destinationPosition.y - recordNode.position.y)
//                recordNode.runInitialAnimation(with: forceVector, delay: index)
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

        switch tap.state {
        case .ended:
            relatedNodes(for: recordNode)
        default:
            return
        }
    }

    @objc
    private func handleSystemClickGesture(_ recognizer: NSClickGestureRecognizer) {
        let clickPosition = recognizer.location(in: recognizer.view)
        let nodePosition = convertPoint(fromView: clickPosition)

//        seekTest(at: nodePosition)

        guard let recordNode = nodes(at: nodePosition).first(where: { $0 is RecordNode }) as? RecordNode else {
            return
        }

        print("ID: \(recordNode.record.id)")

        switch recognizer.state {
        case .ended:
            relatedNodes(for: recordNode)
            return
        default:
            return
        }
    }


    // MARK: Helpers

    private func relatedNodes(for node: RecordNode) {
        if let entity = entityManager.entity(for: node.record) as? RecordEntity {
            entity.intelligenceComponent.stateMachine.enter(TappedState.self)
        }
    }

    private func getRandomPosition() -> CGPoint {
        var point = CGPoint.zero

        guard let position = StartingPositionType(rawValue: arc4random_uniform(4)) else {
            return point
        }

        switch position {
        case .top:
            point = CGPoint(x: randomX(), y: size.height - NodeConfiguration.Record.physicsBodyRadius)
            return point
        case .bottom:
            point = CGPoint(x: randomX(), y: NodeConfiguration.Record.physicsBodyRadius)
            return point
        case .left:
            point = CGPoint(x: NodeConfiguration.Record.physicsBodyRadius, y: randomY())
            return point
        case .right:
            point = CGPoint(x: size.width - NodeConfiguration.Record.physicsBodyRadius, y: randomY())
            return point
        }
    }

    private func randomX() -> CGFloat {
        let lowestValue = Int(NodeConfiguration.Record.physicsBodyRadius)
        let highestValue = Int(size.width - NodeConfiguration.Record.physicsBodyRadius)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }

    private func randomY() -> CGFloat {
        let lowestValue = Int(NodeConfiguration.Record.physicsBodyRadius)
        let highestValue = Int(size.height - NodeConfiguration.Record.physicsBodyRadius)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }

    private func addLinearGravityField(to type: StartingPositionType) {
        var vector: vector_float3
        var size: CGSize
        var position: CGPoint

        switch type {
        case .top:
            vector = vector_float3(0,-1,0)
            size = CGSize(width: frame.width, height: 20)
            position = CGPoint(x: frame.width / 2, y: frame.height - 20)
        case .bottom:
            vector = vector_float3(0,1,0)
            size = CGSize(width: frame.width, height: 20)
            position = CGPoint(x: frame.width / 2, y: 20)
        case .left:
            vector = vector_float3(1,0,0)
            size = CGSize(width: 20, height: frame.height)
            position = CGPoint(x: 20, y: frame.height / 2)
        case .right:
            vector = vector_float3(-1,0,0)
            size = CGSize(width: 20, height: frame.height)
            position = CGPoint(x: frame.width - 20, y: frame.height / 2)
        }

        let field = SKFieldNode.linearGravityField(withVector: vector)
        field.strength = 10
        field.region = SKRegion(size: size)
        field.position = position
        addChild(field)
    }


    // MARK: Debug

    private func createRepulsiveField() {
        let field = SKFieldNode.radialGravityField()
        field.strength = -20
        field.region = SKRegion(radius: 350)
        field.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        field.categoryBitMask = 0x1 << 0
        addChild(field)
    }
}
