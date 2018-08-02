//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


final class RecordEntity: GKEntity {

    // A 2D array of related entities, each index is a new level
    var relatedEntitiesForLevel = [Set<RecordEntity>]() {
        didSet {
            relatedEntities = allRelatedEntities()
        }
    }

    var relatedEntities = Set<RecordEntity>()

    var cluster: NodeCluster? {
        didSet {
            physicsComponent.cluster = cluster
            movementComponent.cluster = cluster
        }
    }

    var record: RecordDisplayable {
        return renderComponent.recordNode.record
    }


    // MARK: Components

    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else {
            fatalError("A RecordEntity must have a RenderComponent")
        }
        return renderComponent
    }

    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = component(ofType: PhysicsComponent.self) else {
            fatalError("A RecordEntity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    var movementComponent: MovementComponent {
        guard let movementComponent = component(ofType: MovementComponent.self) else {
            fatalError("A RecordEntity must have a MovementComponent")
        }
        return movementComponent
    }

    var intelligenceComponent: IntelligenceComponent {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else {
            fatalError("A RecordEntity must have an IntelligenceComponent")
        }
        return intelligenceComponent
    }

    var animationComponent: AnimationComponent {
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

    /// Indicates whether or not the entity has made contact its bounding level node. This property is used to calculate the bounding level node's changing size.
    var hasCollidedWithBoundingNode = false

    /// The previous and current level that the entity belongs to
    var clusterLevel: (previousLevel: Int?, currentLevel: Int?) = (nil, nil)


    // MARK: Initializer

    init(record: RecordDisplayable) {
        super.init()

        let renderComponent = RenderComponent(record: record)
        addComponent(renderComponent)

        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius))
        addComponent(physicsComponent)

        // Connect the 'PhysicsComponent' and the 'RenderComponent'
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody

        let movementComponent = MovementComponent()
        addComponent(movementComponent)

        let animationComponent = AnimationComponent()
        addComponent(animationComponent)

        let intelligenceComponent = IntelligenceComponent(states: [
            WanderState(entity: self),
            SeekTappedEntityState(entity: self),
            SeekBoundingLevelNodeState(entity: self),
            TappedState(entity: self)
        ])
        addComponent(intelligenceComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func set(_ cluster: NodeCluster) {
        self.cluster = cluster
        for entity in relatedEntities {
            entity.cluster = cluster
        }
    }

    func related(to entity: RecordEntity) -> Bool {
        for entities in relatedEntitiesForLevel {
            if entities.contains(entity) {
                return true
            }
        }

        return false
    }

    func updateAgentPositionToMatchNodePosition() {
        agent.position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    /// Calculates the distance between self and another entity
    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = entity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let dY = entity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        return CGFloat(hypotf(Float(dX), Float(dY)))
    }

    /// 'Reset' the entity to initial state so that proper animations and movements can take place
    func reset() {
        // reset RecordEntity properties
        hasCollidedWithBoundingNode = false
        clusterLevel = (nil, nil)
        cluster = nil

        // enter WanderState initial state
        intelligenceComponent.stateMachine.enter(WanderState.self)
    }

    private func allRelatedEntities() -> Set<RecordEntity> {
        var relatedEntities = Set<RecordEntity>()
        for entities in relatedEntitiesForLevel {
            relatedEntities = relatedEntities.union(entities)
        }
        return relatedEntities
    }
}
