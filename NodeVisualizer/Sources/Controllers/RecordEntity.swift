//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


class RecordEntity: GKEntity {

    init(record: RecordDisplayable) {
        super.init()

        let renderComponent = RenderComponent(record: record)
        addComponent(renderComponent)

        let agentComponent = RecordAgent()
        addComponent(agentComponent)
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
