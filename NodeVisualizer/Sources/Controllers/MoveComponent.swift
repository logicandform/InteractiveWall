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
        radius = 10
        behavior = RecordEntityBehavior.behavior(for: self, toSeek: agentToSeek!)
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
//        guard let spriteComponent = entity?.component(ofType: RenderComponent.self) else {
//            return
//        }
//
//        position = vector_float2(x: Float(spriteComponent.recordNode.position.x), y: Float(spriteComponent.recordNode.position.y))
    }

    func agentDidUpdate(_ agent: GKAgent) {
        updateNodePositionToMatchAgentPosition()
//        guard let spriteComponent = entity?.component(ofType: RenderComponent.self) else {
//            return
//        }
//
//        spriteComponent.recordNode.physicsBody?.velocity = CGVector(dx: CGFloat(velocity.x), dy: CGFloat(velocity.y))
    }


    private func updateAgentPositionToMatchNodePosition() {
        let renderComponent = self.renderComponent
        position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    private func updateNodePositionToMatchAgentPosition() {
        renderComponent.recordNode.position = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
    }


}





