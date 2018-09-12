//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


enum EntityState: Equatable {
    case `static`
    case selected
    case seekEntity(RecordEntity)
    case seekLevel(Int)
    case dragging
    case reset
    case remove

    /// Determines if the current state is able to transition into the panning state
    var pannable: Bool {
        switch self {
        case .static, .selected, .dragging, .seekEntity(_):
            return true
        case .seekLevel(_), .reset, .remove:
            return false
        }
    }

    /// Determines if a RecordEntity should recognize a tap when in a given state
    var tappable: Bool {
        switch self {
        case .static, .selected, .seekEntity(_):
            return true
        case .seekLevel(_), .dragging, .reset, .remove:
            return false
        }
    }

    /// Provides the bitmasks for a given state
    var bitMasks: ColliderType {
        switch self {
        case .static, .dragging:
            return ColliderType.defaultBitMasks()
        case .selected:
            return ColliderType.bitMasksForSelectedEntity()
        case .seekLevel(let level):
            return ColliderType.recordNodeBitMasks(forLevel: level)
        case .seekEntity(let entity):
            return ColliderType.bitMasksForSeekingEntity(entity: entity)
        case .reset, .remove:
            return ColliderType.resetBitMasks()
        }
    }

    /// Provides the physics body properties for a given state
    var physicsBodyProperties: PhysicsBodyProperties {
        switch self {
        case .static, .dragging:
            return PhysicsBodyProperties.defaultProperties()
        case .selected:
            return PhysicsBodyProperties.propertiesForSelectedEntity()
        case .seekLevel(let level):
            return PhysicsBodyProperties.properties(forLevel: level)
        case .seekEntity(let entity):
            return PhysicsBodyProperties.properties(forLevel: entity.clusterLevel.currentLevel)
        case .reset, .remove:
            return PhysicsBodyProperties.propertiesForResettingAndRemovingEntity()
        }
    }
}


final class RecordEntity: GKEntity {

    let record: Record
    let relatedRecordsForLevel: RelatedLevels
    let relatedRecords: Set<RecordProxy>
    var hasCollidedWithLayer = false
    var initialPosition = CGPoint.zero
    var cluster: NodeCluster?
    weak var previousCluster: NodeCluster?
    private lazy var stateMachine = RecordStateMachine(entity: self)
    private(set) var clusterLevel: (previousLevel: Int?, currentLevel: Int?) = (nil, nil)

    var state: EntityState {
        return stateMachine.state
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

    var bodyMass: CGFloat {
        return physicsComponent.physicsBodyProperties(for: self).mass
    }

    var isSelected: Bool {
        return clusterLevel.currentLevel == NodeCluster.selectedEntityLevel
    }

    var scene: MainScene {
        guard let scene = renderComponent.recordNode.scene as? MainScene else {
            fatalError("A RecordNode must be presented in a MainScene")
        }
        return scene
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


    // MARK: Initializer

    init(record: Record, levels: RelatedLevels) {
        self.record = record
        self.relatedRecordsForLevel = levels
        var relatedRecords = Set<RecordProxy>()
        for level in levels {
            relatedRecords.formUnion(level)
        }
        self.relatedRecords = relatedRecords
        super.init()

        let renderComponent = RecordRenderComponent(record: record)
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: style.defaultBodyRadius))
        let movementComponent = MovementComponent()
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody
        addComponent(movementComponent)
        addComponent(renderComponent)
        addComponent(physicsComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func set(position: CGPoint) {
        renderComponent.recordNode.position = position
    }

    func set(level: Int) {
        clusterLevel = (clusterLevel.currentLevel, level)
        node.setZ(level: level)
    }

    func set(state: EntityState) {
        if state != stateMachine.state {
            stateMachine.state = state
        }
    }

    func apply(_ animations: [AnimationType]) {
        for animation in animations {
            let action = animation.action(duration: animation.duration)
            perform(action: action, forKey: animation.key)
        }
    }

    func updateBitMasks() {
        physicsComponent.updateBitMasks()
    }

    func setClonedNodeBitMasks() {
        physicsComponent.setClonedNodeBitMasks()
    }

    func updatePhysicsBodyProperties() {
        physicsComponent.updatePhysicsBodyProperties()
    }

    func perform(action: SKAction, forKey key: String) {
        renderComponent.recordNode.run(action, withKey: key)
    }

    func perform(action: SKAction, completion: (() -> Void)? = nil) {
        renderComponent.recordNode.run(action) {
            completion?()
        }
    }

    func removeAnimation(forKey key: String) {
        renderComponent.recordNode.removeAction(forKey: key)
    }

    /// 'Reset' the entity to initial state so that proper animations and movements can take place
    func reset() {
        hasCollidedWithLayer = false
        clusterLevel = (nil, nil)
        cluster = nil
        previousCluster = nil
        renderComponent.recordNode.scale(to: style.defaultNodeSize)
        set(position: initialPosition)
    }

    func resetBitMasks() {
        physicsComponent.resetBitMasks()
    }

    func resetPhysicsBodyProperties() {
        physicsComponent.resetPhysicsBodyProperties()
    }

    func clone() -> RecordEntity {
        return RecordEntity(record: record, levels: relatedRecordsForLevel)
    }

    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = entity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let dY = entity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        return CGFloat(hypotf(Float(dX), Float(dY)))
    }
}
