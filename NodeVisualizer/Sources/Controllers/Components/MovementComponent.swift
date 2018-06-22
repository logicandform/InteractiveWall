//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// This class allows RecordEntity to move/seek proportional to the radius between the target (tapped/selected node) and the its own node (i.e. the related node)
class MovementComponent: GKComponent {

    private static let strength: CGFloat = 10000
    let dt: CGFloat = 1/60

    var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A MovementComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }

    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity?.component(ofType: PhysicsComponent.self) else {
            fatalError("A MovementComponent's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    var relatedEntities: [RecordEntity] = []
    var entitesToAvoid: [RecordEntity] = []

    var entityToSeek: RecordEntity?


    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // check to see if the record entity is in the correct state (i.e. it is seeking a tapped record node)
        guard let intelligenceComponent = entity?.component(ofType: IntelligenceComponent.self),
            intelligenceComponent.stateMachine.currentState is SeekState,
            let targetEntity = entityToSeek else {
            return
        }

        // periodically check the radius between its own entity and the entityToSeek, and apply the appropriate physics
        let renderComponent = self.renderComponent
        let physicsComponent = self.physicsComponent

        let targetEntityMass = targetEntity.renderComponent.recordNode.physicsBody!.mass * MovementComponent.strength
        let entityMass = renderComponent.recordNode.physicsBody!.mass * MovementComponent.strength

        let displacement = CGVector(dx: targetEntity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x, dy: targetEntity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y)
        let radius = distanceBetween(starting: renderComponent.recordNode, to: targetEntity.renderComponent.recordNode)

        let force = (targetEntityMass * entityMass) / (radius * radius)
        let normal = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)
        let impulse = CGVector(dx: normal.dx * force * dt, dy: normal.dy * force * dt)

        physicsComponent.physicsBody.velocity = CGVector(dx: physicsComponent.physicsBody.velocity.dx + impulse.dx, dy: physicsComponent.physicsBody.velocity.dy + impulse.dy)
    }


    private func distanceBetween(starting node: SKNode, to target: SKNode) -> CGFloat {
        let dX = Float(target.position.x - node.position.x)
        let dY = Float(target.position.y - node.position.y)
        return CGFloat(hypotf(dX, dY))
    }


}







