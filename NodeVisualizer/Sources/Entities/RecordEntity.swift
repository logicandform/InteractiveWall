//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


enum EntityState: Equatable {
    case `static`
    case tapped
    case seekEntity(RecordEntity)
    case seekLevel(Int)
    case panning

    var pannable: Bool {
        switch self {
        case .static, .tapped, .panning:
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
    var hasCollidedWithBoundingNode = false
    var initialPosition = CGPoint.zero
    var cluster: NodeCluster?
    weak var previousCluster: NodeCluster?
    var tappable = true
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

    var bodyRadius: CGFloat {
        return renderComponent.recordNode.frame.width / 2
    }

    override var description: String {
        return "( [RecordEntity] ID: \(record.id), type: \(record.type), State: \(state) )"
    }


    // MARK: Components

    private var renderComponent: RecordRenderComponent {
        guard let renderComponent = component(ofType: RecordRenderComponent.self) else {
            fatalError("A RecordEntity must have a RecordRenderComponent")
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

        let renderComponent = RecordRenderComponent(record: record)
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: style.defaultNodePhysicsBodyRadius))
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

    func set(size: CGSize) {
        renderComponent.recordNode.scale(to: size)
    }
    
    func set(level: Int) {
        clusterLevel = (clusterLevel.currentLevel, level)
    }

    func set(state: EntityState) {
        if movementComponent.state == state { return }
        movementComponent.state = state
    }

    func set(_ states: [AnimationState]) {
        animationComponent.requestedAnimationStates = states
    }

    func updateBitMasks() {
        physicsComponent.updateBitMasks()
    }

    func setClonedNodeBitMasks() {
        physicsComponent.setClonedNodeBitMasks()
    }

    func perform(action: SKAction, completion: (() -> Void)? = nil) {
        renderComponent.recordNode.run(action) {
            completion?()
        }
    }

    /// 'Reset' the entity to initial state so that proper animations and movements can take place
    func reset() {
        hasCollidedWithBoundingNode = false
        clusterLevel = (nil, nil)
        cluster = nil
        previousCluster = nil
        set(state: .static)
    }

    func resetBitMasks() {
        physicsComponent.resetBitMasks()
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
