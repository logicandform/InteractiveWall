//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


enum EntityState: Equatable {
    case falling
    case tapped
    case seekEntity(RecordEntity)
    case seekLevel(Int)
    case panning

    var pannable: Bool {
        switch self {
        case .falling, .tapped, .panning:
            return true
        default:
            return false
        }
    }
}


final class RecordEntity: GKEntity {

    let record: RecordDisplayable
    let relatedRecordsForLevel: RelatedLevels
    let relatedRecords: Set<RecordProxy>
    var cluster: NodeCluster?
    var hasCollidedWithBoundingNode = false
    var isClonedEntity = false
    private(set) var clusterLevel: (previousLevel: Int?, currentLevel: Int?) = (nil, nil)

    var state: EntityState {
        return movementComponent.state
    }

    var position: CGPoint {
        return renderComponent.recordNode.position
    }

    var physicsBody: SKPhysicsBody {
        return physicsComponent.physicsBody
    }

    var node: RecordNode {
        return renderComponent.recordNode
    }

    override var description: String {
        return "( [RecordEntity] ID: \(record.id), type: \(record.type), State: \(state) )"
    }

    private struct Constants {
        static let tappedEntitylevel = -1
    }


    // MARK: Components

    private var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else {
            fatalError("A RecordEntity must have a RenderComponent")
        }
        return renderComponent
    }

    private var physicsComponent: PhysicsComponent {
        guard let physicsComponent = component(ofType: PhysicsComponent.self) else {
            fatalError("A RecordEntity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    private var movementComponent: MovementComponent {
        guard let movementComponent = component(ofType: MovementComponent.self) else {
            fatalError("A RecordEntity must have a MovementComponent")
        }
        return movementComponent
    }

    private var animationComponent: AnimationComponent {
        guard let animationComponent = component(ofType: AnimationComponent.self) else {
            fatalError("A RecordEntity must have an AnimationComponent")
        }
        return animationComponent
    }

    var agent: RecordAgent {
        guard let agent = component(ofType: RecordAgent.self) else {
            fatalError("A RecordEntity must have a GKAgent2D Component")
        }
        return agent
    }


    // MARK: Initializer

    init(record: RecordDisplayable, levels: RelatedLevels) {
        self.record = record
        self.relatedRecordsForLevel = levels
        var relatedRecords = Set<RecordProxy>()
        for level in levels {
            relatedRecords.formUnion(level)
        }
        self.relatedRecords = relatedRecords
        super.init()

        let renderComponent = RenderComponent(record: record)
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: style.nodePhysicsBodyRadius))
        let movementComponent = MovementComponent()
        let animationComponent = AnimationComponent()
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody
        addComponent(movementComponent)
        addComponent(renderComponent)
        addComponent(physicsComponent)
        addComponent(animationComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func set(position: CGPoint) {
        renderComponent.recordNode.position = position
    }

    func set(state: EntityState) {
        if movementComponent.state == state { return }
        movementComponent.state = state

        switch state {
        case .tapped:
            clusterLevel = (previousLevel: clusterLevel.currentLevel, currentLevel: Constants.tappedEntitylevel)
        case .seekLevel(let level):
            clusterLevel = (previousLevel: clusterLevel.currentLevel, currentLevel: level)
//            physicsComponent.setRecordNodeLevelInteractingBitMasks(forLevel: level)
            physicsComponent.updateBitMasks()
        case .seekEntity(_):
            physicsComponent.updateBitMasks()
        default:
            break
        }
    }

    func set(state: AnimationState) {
        animationComponent.requestedAnimationState = state
    }

    func setBitMasks(forLevel level: Int) {
        physicsComponent.setInteractingBitMasks(forLevel: level)
    }

    func updateBitMasks() {
        physicsComponent.updateBitMasks()
    }

    func setClonedNodeBitMasks() {
        physicsComponent.setClonedNodeBitMasks()
    }

    func updateAgentPositionToMatchNodePosition() {
        agent.position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    func run(action: SKAction) {
        renderComponent.recordNode.run(action) { [weak self] in
            self?.renderComponent.recordNode.removeAllActions()
        }
    }

    /// 'Reset' the entity to initial state so that proper animations and movements can take place
    func reset() {
        hasCollidedWithBoundingNode = false
        clusterLevel = (nil, nil)
        cluster = nil
        physicsComponent.reset()
        set(state: .falling)
    }

    func clone() -> RecordEntity {
        return RecordEntity(record: record, levels: relatedRecordsForLevel)
    }

    /// Calculates the distance between self and another entity
    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = entity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let dY = entity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        return CGFloat(hypotf(Float(dX), Float(dY)))
    }
}
