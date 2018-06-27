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

    var agent: RecordAgent {
        guard let agent = component(ofType: RecordAgent.self) else {
            fatalError("A RecordEntity must have a GKAgent2D Component")
        }
        return agent
    }

    var relatedEntities: [RecordEntity] = []

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


    func updateAgentPositionToMatchNodePosition() {
        guard let renderComponent = component(ofType: RenderComponent.self), let agent = component(ofType: RecordAgent.self) else {
            return
        }

        agent.position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    func distance(to otherAgent: GKAgent2D) -> Float {
        let dX = agent.position.x - otherAgent.position.x
        let dY = agent.position.y - otherAgent.position.y
        return hypotf(dX, dY)
    }
}
