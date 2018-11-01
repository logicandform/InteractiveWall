//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


final class RecordEntity: GKEntity {

    let record: Record
    let relatedRecordsForLevel: RelatedLevels
    let relatedRecords: Set<RecordProxy>
    var hasCollidedWithLayer = false
    var initialPosition: CGPoint?
    var cluster: NodeCluster?
    weak var previousCluster: NodeCluster?
    var dragVelocity: CGVector?
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


    // MARK: Components

    private var renderComponent: RecordRenderComponent {
        guard let renderComponent = component(ofType: RecordRenderComponent.self) else {
            fatalError("A RecordEntity must have a RecordRenderComponent")
        }
        return renderComponent
    }

    private var physicsComponent: RecordPhysicsComponent {
        guard let physicsComponent = component(ofType: RecordPhysicsComponent.self) else {
            fatalError("A RecordEntity must have a RecordPhysicsComponent")
        }
        return physicsComponent
    }

    private var movementComponent: RecordMovementComponent {
        guard let movementComponent = component(ofType: RecordMovementComponent.self) else {
            fatalError("A RecordEntity must have a RecordMovementComponent")
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
        let physicsComponent = RecordPhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: renderComponent.recordNode.size.width / 2))
        let movementComponent = RecordMovementComponent()
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody
        addComponent(movementComponent)
        addComponent(renderComponent)
        addComponent(physicsComponent)
        updateBitMasks()
        updatePhysicsProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func set(position: CGPoint?) {
        if let position = position {
            renderComponent.recordNode.position = position
        }
    }

    func set(level: Int) {
        clusterLevel = (clusterLevel.currentLevel, level)
        node.setZ(level: level, clusterID: cluster?.id ?? 0)
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
        let mask = BitMaskGenerator.bitMask(for: self)
        physicsBody.categoryBitMask = mask
        physicsBody.collisionBitMask = mask
        physicsBody.contactTestBitMask = mask
    }

    func updatePhysicsProperties() {
        physicsBody.isDynamic = state.dynamic
        physicsBody.restitution = state.restitution
        physicsBody.friction = state.friction
        physicsBody.linearDamping = state.linearDamping
        physicsBody.angularDamping = state.angularDamping
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

    func resetProperties() {
        hasCollidedWithLayer = false
        clusterLevel = (nil, nil)
        cluster = nil
        previousCluster = nil
    }

    /// 'Reset' the entity to initial state so that proper animations and movements can take place
    func resetNode() {
        renderComponent.recordNode.scale(to: style.defaultNodeSize)
        set(position: initialPosition)
    }

    func clone() -> RecordEntity {
        let clone = RecordEntity(record: record, levels: relatedRecordsForLevel)
        clone.initialPosition = initialPosition
        return clone
    }

    /// Calculates the distance between self and another entity
    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = entity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let dY = entity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        return CGFloat(hypotf(Float(dX), Float(dY)))
    }
}
