//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import GameplayKit


/// A 'GKComponent' that provides an 'GKAgent' for an entity. The GKAgent component provides movement to an entity based on sets of goals and constraints.
class RecordAgent: GKAgent2D, GKAgentDelegate {

    private var renderComponent: RecordRenderComponent {
        guard let renderComponent = entity?.component(ofType: RecordRenderComponent.self) else {
            fatalError("A RecordEntity must have a RecordRenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    override init() {
        super.init()
        delegate = self

        maxSpeed = style.nodeAgentMaxSpeed
        maxAcceleration = style.nodeAgentMaxAcceleration
        radius = style.nodeAgentRadius
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
