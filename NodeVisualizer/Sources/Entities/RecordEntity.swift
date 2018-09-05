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
}

struct PhysicsBodyProperties {
    let mass: CGFloat
    let restitution: CGFloat
    let friction: CGFloat
    let linearDamping: CGFloat
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

    var isSelected: Bool {
        return clusterLevel.currentLevel == NodeCluster.selectedEntityLevel
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
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: style.defaultNodePhysicsBodyRadius))
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
        resetBitMasks()
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

    func clone() -> RecordEntity {
        return RecordEntity(record: record, levels: relatedRecordsForLevel)
    }

    /// Calculates the distance between self and another entity
    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = entity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let dY = entity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        return CGFloat(hypotf(Float(dX), Float(dY)))
    }

    func setPhysicsBodyProperties() {
        let properties = physicsBodyProperties()
        physicsBody.mass = properties.mass
        physicsBody.restitution = properties.restitution
        physicsBody.friction = properties.restitution
        physicsBody.linearDamping = properties.linearDamping
    }

    /// Provides the physics body properties depending on the entity's state and level
    func physicsBodyProperties() -> PhysicsBodyProperties {
        if hasCollidedWithLayer {
            return propertiesForBoundingNodeCollision()
        } else if case .seekEntity(cluster?.selectedEntity) = state {
            return propertiesForSeekingEntity()
        } else if let cluster = cluster, cluster.selectedEntity.state == .dragging {
            return propertiesForSeekingPanningEntity()
        } else if state == .selected {
            return propertiesForSelectedEntity()
        } else {
            return defaultPhysicsBodyProperties()
        }
    }


    // MARK: Helpers

    private func defaultPhysicsBodyProperties() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.defaultBodyMass,
            restitution: style.defaultBodyRestitution,
            friction: style.defaultBodyFriction,
            linearDamping: style.defaultLinearDamping)
    }

    private func propertiesForBoundingNodeCollision() -> PhysicsBodyProperties {
        guard let level = clusterLevel.currentLevel else {
            return defaultPhysicsBodyProperties()
        }

        var mass: CGFloat
        var restitution: CGFloat
        var friction: CGFloat
        var damping: CGFloat

        switch level {
        case 0:
            mass = style.collidedLevelZeroBodyMass
            restitution = style.collidedLevelZeroBodyRestitution
            friction = style.collidedLevelZeroBodyFriction
            damping = style.collidedLevelZeroBodyLinearDamping
        case 1:
            mass = style.collidedLevelOneBodyMass
            restitution = style.collidedLevelOneBodyRestitution
            friction = style.collidedLevelOneBodyFriction
            damping = style.collidedLevelOneBodyLinearDamping
        case 2:
            mass = style.collidedLevelTwoBodyMass
            restitution = style.collidedLevelTwoBodyRestitution
            friction = style.collidedLevelTwoBodyFriction
            damping = style.collidedLevelTwoBodyLinearDamping
        case 3:
            mass = style.collidedLevelThreeBodyMass
            restitution = style.collidedLevelThreeBodyRestitution
            friction = style.collidedLevelThreeBodyFriction
            damping = style.collidedLevelThreeBodyLinearDamping
        case 4:
            mass = style.collidedLevelFourBodyMass
            restitution = style.collidedLevelFourBodyRestitution
            friction = style.collidedLevelFourBodyFriction
            damping = style.collidedLevelFourBodyLinearDamping
        default:
            return defaultPhysicsBodyProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping)
    }

    private func propertiesForSeekingEntity() -> PhysicsBodyProperties {
        guard let level = clusterLevel.currentLevel else {
            return defaultPhysicsBodyProperties()
        }

        var mass: CGFloat
        var restitution: CGFloat
        var friction: CGFloat
        var damping: CGFloat

        switch level {
        case 0:
            mass = style.seekingLevelZeroBodyMass
            restitution = style.seekingLevelZeroBodyRestitution
            friction = style.seekingLevelZeroBodyFriction
            damping = style.seekingLevelZeroBodyLinearDamping
        case 1:
            mass = style.seekingLevelOneBodyMass
            restitution = style.seekingLevelOneBodyRestitution
            friction = style.seekingLevelOneBodyFriction
            damping = style.seekingLevelOneBodyLinearDamping
        case 2:
            mass = style.seekingLevelTwoBodyMass
            restitution = style.seekingLevelTwoBodyRestitution
            friction = style.seekingLevelTwoBodyFriction
            damping = style.seekingLevelTwoBodyLinearDamping
        case 3:
            mass = style.seekingLevelThreeBodyMass
            restitution = style.seekingLevelThreeBodyRestitution
            friction = style.seekingLevelThreeBodyFriction
            damping = style.seekingLevelThreeBodyLinearDamping
        case 4:
            mass = style.seekingLevelFourBodyMass
            restitution = style.seekingLevelFourBodyRestitution
            friction = style.seekingLevelFourBodyFriction
            damping = style.seekingLevelFourBodyLinearDamping
        default:
            return defaultPhysicsBodyProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping)
    }

    private func propertiesForSelectedEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.selectedBodyMass,
            restitution: style.selectedBodyRestitution,
            friction: style.selectedBodyFriction,
            linearDamping: style.selectedLinearDamping)
    }

    private func propertiesForSeekingPanningEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.seekingPannedBodyMass,
            restitution: style.seekingPannedBodyRestitution,
            friction: style.seekingPannedBodyFriction,
            linearDamping: style.seekingPannedBodyLinearDamping)
    }
}
