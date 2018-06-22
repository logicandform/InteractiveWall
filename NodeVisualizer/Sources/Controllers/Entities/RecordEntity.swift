//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


class RecordEntity: GKEntity {

    enum RecordEntityMandate {
        case wander
        case seekRecordAgent(GKAgent2D)
    }

    var mandate: RecordEntityMandate

    var behaviorForCurrentMandate: GKBehavior {
        switch mandate {
        case .wander:
            break
        case .seekRecordAgent(let agent):
            return RecordEntityBehavior.behavior(seek: agent, agentsToSeparateFrom: agentsToSeparateFrom)
//            return RecordEntityBehavior.behavior(toSeek: agent)
        }
        return GKBehavior()
    }

    var agent: RecordAgent {
        guard let agent = component(ofType: RecordAgent.self) else {
            fatalError("A RecordEntity must have a GKAgent2D component")
        }
        return agent
    }

    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else {
            fatalError("A RecordEntity must have a Render component")
        }
        return renderComponent
    }

    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = component(ofType: PhysicsComponent.self) else {
            fatalError("A RecordEntity must have a Physics component")
        }
        return physicsComponent
    }

    var intelligenceComponent: IntelligenceComponent {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else {
            fatalError("A RecordEntity must have an Intelligence component")
        }
        return intelligenceComponent
    }

    var manager: EntityManager!
    var agentsToSeparateFrom: [GKAgent2D]!


    init(record: TestingEnvironment.Record) {
        mandate = .wander

        super.init()

        let renderComponent = RenderComponent(record: record)
        addComponent(renderComponent)

        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius))
        addComponent(physicsComponent)

        // Connect the 'PhysicsComponent' and the 'RenderComponent'
        renderComponent.recordNode.physicsBody = physicsComponent.physicsBody

        let agentComponent = RecordAgent()
        addComponent(agentComponent)

        let intelligenceComponent = IntelligenceComponent(states: [
            WanderState(entity: self),
            SeekState(entity: self),
            ConnectedState(entity: self)
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
