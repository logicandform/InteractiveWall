//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


class RecordEntity: GKEntity {

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

    var relatedEntities: [RecordEntity] = []
    var hasReset: Bool = false

    private(set) var manager: EntityManager


    init(record: TestingEnvironment.Record, manager: EntityManager) {
        self.manager = manager

        super.init()

        let renderComponent = RenderComponent(record: record)
        addComponent(renderComponent)

        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius))
        addComponent(physicsComponent)

        // Connect the 'PhysicsComponent' and the 'RenderComponent'
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody

//        let agentComponent = RecordAgent()
//        addComponent(agentComponent)

        let movementComponent = MovementComponent()
        addComponent(movementComponent)

        let animationComponent = AnimationComponent()
        addComponent(animationComponent)

        let intelligenceComponent = IntelligenceComponent(states: [
            WanderState(entity: self),
            SeekState(entity: self),
            TappedState(entity: self)
        ])
        addComponent(intelligenceComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func updateAgentPositionToMatchNodePosition() {
        agent.position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    func distance(to otherAgent: GKAgent2D) -> Float {
        let dX = agent.position.x - otherAgent.position.x
        let dY = agent.position.y - otherAgent.position.y
        return hypotf(dX, dY)
    }



    func resetEntities(entities: [RecordEntity], completion: @escaping () -> Void) {
        guard let entityToReset = entities.first, !entityToReset.hasReset else {
            completion()
            return
        }

        entityToReset.intelligenceComponent.stateMachine.enter(WanderState.self)
        hasReset = true

        entityToReset.resetEntities(entities: entityToReset.relatedEntities) {
            let newEntities = Array(entities[1..<entities.count])
            self.resetEntities(entities: newEntities, completion: completion)
        }
    }





    func resetRelatedEntities(entities: [RecordEntity], excluding: RecordEntity, completion: @escaping () -> Void) {
        guard let entityToReset = entities.first, entityToReset != excluding else {
            completion()
            return
        }

        entityToReset.intelligenceComponent.stateMachine.enter(WanderState.self)

        entityToReset.resetEntities(entities: entityToReset.relatedEntities) {
            let newEntities = Array(entities[1..<entities.count])
            self.resetRelatedEntities(entities: newEntities, excluding: self, completion: completion)
        }
    }

    func pleaseWork(entities: [RecordEntity], excluding: RecordEntity, completion: @escaping () -> Void) {
        guard let entityToReset = entities.first, entityToReset != excluding else {
            completion()
            return
        }

        entityToReset.intelligenceComponent.stateMachine.enter(WanderState.self)

        entityToReset.pleaseWork(entities: entityToReset.relatedEntities, excluding: self) {
            let newEntities = Array(entities[1..<entities.count])
            self.pleaseWork(entities: newEntities, excluding: excluding, completion: completion)
        }
    }
}









