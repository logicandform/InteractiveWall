//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var records: [RecordDisplayable]!
    var gestureManager: GestureManager!

    var entityManager: EntityManager!
    var agentToSeek: GKAgent2D!
    var lastUpdateTimeInterval: TimeInterval = 0

    private enum StartingPositionType: UInt32 {
        case top = 0
        case bottom = 1
        case left = 2
        case right = 3
    }

    private struct BitMasks {
        struct FieldBitMasks {
            static let testBitMaskCategory: UInt32 = 0x1 << 0
            static let testBitMask1Category: UInt32 = 0x1 << 1
        }
    }


    // MARK: Lifecycle
    
    override func didMove(to view: SKView) {
        entityManager = EntityManager(scene: self)

        addGestures(to: view)
        setupSystemGesturesForTest(to: view)

        addPhysicsToScene()
        addRecordNodesToScene()
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime

        entityManager.update(deltaTime)
    }

    override func didFinishUpdate() {

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
    }

    private func addRecordNodesToScene() {
        records.enumerated().forEach { index, record in
            let recordEntity = RecordEntity(record: record)

            if let recordNode = recordEntity.component(ofType: RenderComponent.self)?.recordNode {
                recordNode.position.x = randomX()
                recordNode.position.y = randomY()
                recordNode.zPosition = 1

                recordEntity.updateAgentPositionToMatchNodePosition()
                entityManager.add(recordEntity)
                addChild(recordNode)

//                let destinationPosition = getRandomPosition()
//                let forceVector = CGVector(dx: destinationPosition.x - recordNode.position.x, dy: destinationPosition.y - recordNode.position.y)
//                recordNode.runInitialAnimation(with: forceVector, delay: index)
            }
        }
    }


    // MARK: Gesture Handlers

    private func createGravityField(at point: CGPoint, to node: RecordNode) {
        let field = SKFieldNode.radialGravityField()
        field.strength = 10
        field.falloff = 1
        field.minimumRadius = 5
        field.categoryBitMask = BitMasks.FieldBitMasks.testBitMaskCategory
//        field.position = node.position
        node.physicsBody?.isDynamic = false
        node.addChild(field)

        for case let recordNode as RecordNode in children {
            if recordNode.record.id == 48 {
                let field1 = SKFieldNode.radialGravityField()
                field1.strength = 35
                field1.falloff = 1
                field1.minimumRadius = 5
                field1.categoryBitMask = BitMasks.FieldBitMasks.testBitMask1Category
                recordNode.physicsBody?.isDynamic = false
                recordNode.addChild(field1)
            } else {
                recordNode.physicsBody?.fieldBitMask = BitMasks.FieldBitMasks.testBitMaskCategory
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        if let node50 = children.compactMap({ $0 as? RecordNode }).filter({ $0.record.id == 50 }).first {
            node50.physicsBody?.fieldBitMask = BitMasks.FieldBitMasks.testBitMask1Category
            let move = SKAction.moveBy(x: 350, y: 350, duration: 5)
            node50.run(move)
        }
    }

    func doSomething(at point: CGPoint, to node: RecordNode? = nil) {
        agentToSeek = GKAgent2D()
        agentToSeek.position = vector_float2(x: Float(point.x), y: Float(point.y))

//        for entity in entityManager.entities {
//            entity.addComponent(MoveComponent(agentToSeek: agentToSeek))
//
//            for system in entityManager.componentSystems {
//                system.addComponent(foundIn: entity)
//            }
//        }
    }

    @objc
    private func handleSystemClickGesture(_ recognizer: NSClickGestureRecognizer) {
        print("click")

        let clickPosition = recognizer.location(in: recognizer.view)
        let nodePosition = convertPoint(fromView: clickPosition)

//        doSomething(at: nodePosition)

        guard let recordNode = nodes(at: nodePosition).first(where: { $0 is RecordNode }) as? RecordNode else {
            return
        }

        print(recordNode.record.id)
        print(recordNode.record.type)

        switch recognizer.state {
        case .ended:
            relatedNodes(for: recordNode)
        default:
            return
        }
    }

    private func relatedNodes(for node: RecordNode) {
        let identifier = DataManager.RecordIdentifier(id: node.record.id, type: node.record.type)
        let relatedRecords = DataManager.instance.relatedRecords(for: identifier)
        print(relatedRecords)

        let tappedRecordEntity = entityManager.entity(for: node.record)
        let tappedRecordAgent = tappedRecordEntity?.component(ofType: RecordAgent.self)
        let relatedRecordEntities = entityManager.entities(for: relatedRecords)

        for relatedRecordEntity in relatedRecordEntities {
            let moveComponent = MoveComponent(agentToSeek: tappedRecordAgent)
            entityManager.add(component: moveComponent, to: relatedRecordEntity)
        }
    }

    private func handleTapGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position else {
            return
        }

        switch tap.state {
        case .ended:
            print(position)
            return
        default:
            return
        }
    }


    // MARK: Helpers

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
