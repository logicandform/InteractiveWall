//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class RecordEntity: GKEntity {

    init(record: RecordDisplayable) {
        super.init()
        
        let spriteComponent = SpriteComponent(record: record)
        addComponent(spriteComponent)

        let agentComponent = AgentComponent()
        addComponent(agentComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class AgentComponent: GKAgent2D, GKAgentDelegate {

    override init() {
        super.init()
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    // MARK: GKAgentDelegate

    func agentWillUpdate(_ agent: GKAgent) {
        guard let spriteComponent = entity?.component(ofType: SpriteComponent.self) else {
            return
        }

        position = vector_float2(x: Float(spriteComponent.recordNode.position.x), y: Float(spriteComponent.recordNode.position.y))
    }

    func agentDidUpdate(_ agent: GKAgent) {
        guard let spriteComponent = entity?.component(ofType: SpriteComponent.self) else {
            return
        }

        spriteComponent.recordNode.physicsBody?.velocity = CGVector(dx: CGFloat(velocity.x), dy: CGFloat(velocity.y))
    }
}





