//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that provides an 'GKAgent' for an entity. The GKAgent component provides movement to an entity based on sets of goals and constraints.
*/

import Foundation
import GameplayKit


class RecordAgent: GKAgent2D, GKAgentDelegate {

    private var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A RecordEntity must have a RenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    override init() {
        super.init()
        delegate = self

        maxSpeed = NodeConfiguration.Record.agentMaxSpeed
        maxAcceleration = NodeConfiguration.Record.agentMaxAcceleration
        radius = NodeConfiguration.Record.agentRadius
        behavior = GKBehavior()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }


    // MARK: GKAgentDelegate

    func agentWillUpdate(_ agent: GKAgent) {
        let renderComponent = self.renderComponent
        position = vector_float2(x: Float(renderComponent.recordNode.position.x), y: Float(renderComponent.recordNode.position.y))
    }

    func agentDidUpdate(_ agent: GKAgent) {
        renderComponent.recordNode.position = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
    }
}
