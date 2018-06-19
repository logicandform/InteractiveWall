//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var records: [RecordDisplayable]!
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

    private struct BitMasks {
        struct FieldBitMasks {
            static let testBitMaskCategory: UInt32 = 0x1 << 0
            static let testBitMask1Category: UInt32 = 0x1 << 1
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
    }


    // MARK: Setup

    private func addGestures(to view: SKView) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: view)
        tapGesture.gestureUpdated = handleTapGesture(_:)
    }

    private func setupSystemGesturesForTest(to view: SKView) {
        let tapGesture = NSClickGestureRecognizer(target: self, action: #selector(handleSystemClickGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    private func addPhysicsToScene() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero

        for type in StartingPositionType.allValues {
            addLinearGravityField(to: type)
        }
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

    private func addRecordNodesToScene() {
        records.prefix(10).enumerated().forEach { index, record in
            let recordEntity = RecordEntity(record: record)

            if let recordNode = recordEntity.component(ofType: RenderComponent.self)?.recordNode {
                recordNode.position.x = randomX()
                recordNode.position.y = randomY()
                recordNode.zPosition = 1
                recordEntity.updateAgentPositionToMatchNodePosition()

                let screenBoundsConstraint = SKConstraint.positionX(SKRange(lowerLimit: 0, upperLimit: frame.width), y: SKRange(lowerLimit: 0, upperLimit: frame.height))
                recordNode.constraints = [screenBoundsConstraint]

                entityManager.add(recordEntity)
                addChild(recordNode)

                if let intelligenceComponent = recordEntity.component(ofType: IntelligenceComponent.self) {
                    intelligenceComponent.enterInitialState()
                }

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

        print("ID: \(recordNode.record.id) , Type: \(recordNode.record.type)")

        switch tap.state {
        case .ended:
            relatedNodes(for: recordNode)
//            createGravityField(at: nodePosition, to: recordNode)
        default:
            return
        }
    }

    @objc
    private func handleSystemClickGesture(_ recognizer: NSClickGestureRecognizer) {
        let clickPosition = recognizer.location(in: recognizer.view)
        let nodePosition = convertPoint(fromView: clickPosition)

        seekTest(at: nodePosition)

        guard let recordNode = nodes(at: nodePosition).first(where: { $0 is RecordNode }) as? RecordNode else {
            return
        }

        print("ID: \(recordNode.record.id) , Type: \(recordNode.record.type)")

        switch recognizer.state {
        case .ended:
//            relatedNodes(for: recordNode)
//            useSKConstraints(node: recordNode)
            return
        default:
            return
        }
    }


    // MARK: Helpers

    private func relatedNodes(for node: RecordNode) {
        let identifier = DataManager.RecordIdentifier(id: node.record.id, type: node.record.type)
        let relatedRecords = DataManager.instance.relatedRecords(for: identifier)
        print(relatedRecords)

        let tappedRecordEntity = entityManager.entity(for: node.record)
        let tappedRecordAgent = tappedRecordEntity?.component(ofType: RecordAgent.self)
        let relatedRecordEntities = entityManager.entities(for: relatedRecords)

        for entity in relatedRecordEntities {
            let moveBehavior = RecordEntityBehavior.behavior(toSeek: tappedRecordAgent)
            entity.component(ofType: RecordAgent.self)?.behavior = moveBehavior
        }
    }

    // Debug
    private func seekTest(at point: CGPoint, to node: RecordNode? = nil) {
        agentToSeek = GKAgent2D()
        agentToSeek.position = vector_float2(x: Float(point.x), y: Float(point.y))

        for case let entity as RecordEntity in entityManager.entities {
            entity.mandate = .seekRecordAgent(agentToSeek)
            if let intelligenceComponent = entity.component(ofType: IntelligenceComponent.self) {
                intelligenceComponent.stateMachine.enter(SeekState.self)
            }

//            let move = RecordEntityBehavior.behavior(toSeek: agentToSeek)
//            let agent = entity.component(ofType: RecordAgent.self)
//            agent?.behavior = move
        }
    }

    // Debug
    private func useSKConstraints(node: RecordNode) {
        let constraint = SKConstraint.distance(SKRange(upperLimit: 80), to: node)

        for case let node as RecordNode in children {
            if node.record.id != 48 {
                node.constraints?.append(constraint)
            }
        }
    }

    // Debug
    private func createGravityField(at point: CGPoint, to node: RecordNode) {
        let field = SKFieldNode.radialGravityField()
        field.strength = 1
        field.falloff = 1
        field.categoryBitMask = BitMasks.FieldBitMasks.testBitMaskCategory
//        field.position = node.position
        node.physicsBody?.isDynamic = false
        node.addChild(field)

        let identifier = DataManager.RecordIdentifier(id: node.record.id, type: node.record.type)
        let relatedRecords = DataManager.instance.relatedRecords(for: identifier)
        let relatedRecordEntities = entityManager.entities(for: relatedRecords)

        for entity in relatedRecordEntities {
            entity.component(ofType: RenderComponent.self)?.recordNode.physicsBody?.fieldBitMask = BitMasks.FieldBitMasks.testBitMaskCategory
        }
    }

    private func getRandomPosition() -> CGPoint {
        var point = CGPoint.zero

        guard let position = StartingPositionType(rawValue: arc4random_uniform(4)) else {
            return point
        }

        switch position {
        case .top:
            point = CGPoint(x: randomX(), y: size.height - 20)
            return point
        case .bottom:
            point = CGPoint(x: randomX(), y: 20)
            return point
        case .left:
            point = CGPoint(x: 20, y: randomY())
            return point
        case .right:
            point = CGPoint(x: size.width - 20, y: randomY())
            return point
        }
    }

    private func randomX() -> CGFloat {
        let lowestValue = 20
        let highestValue = Int(size.width - 20)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }

    private func randomY() -> CGFloat {
        let lowestValue = 20
        let highestValue = Int(size.height - 20)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt(upperBound: highestValue))
    }
}
