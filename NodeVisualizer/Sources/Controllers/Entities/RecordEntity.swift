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
            return RecordEntityBehavior.behavior(toSeek: agent)
        }
        return GKBehavior()
    }


    init(record: RecordDisplayable) {
        mandate = .wander

        super.init()

        let renderComponent = RenderComponent(record: record)
        addComponent(renderComponent)

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
}
