//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class MoveComponent: GKAgent2D, GKAgentDelegate {

    private var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError()
        }
        return renderComponent
    }


    init(agentToSeek: GKAgent2D?) {
        super.init()

        delegate = self
        maxSpeed = 200
        maxAcceleration = 100
        mass = 0.01
        behavior = RecordEntityBehavior.behavior(toSeek: agentToSeek!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }


    // MARK: GKAgentDelegate

    func agentWillUpdate(_ agent: GKAgent) {
        updateAgentPositionToMatchNodePosition()
    }

    func agentDidUpdate(_ agent: GKAgent) {
        updateNodePositionToMatchAgentPosition()
    }


    private func updateAgentPositionToMatchNodePosition() {
        let renderComponent = self.renderComponent
        position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    private func updateNodePositionToMatchAgentPosition() {
        renderComponent.recordNode.position = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
    }
}
