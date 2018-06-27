//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that enables an entity to seek a target node (i.e. a tapped node) and creates a gravitational attraction between the two entities.
*/

import Foundation
import SpriteKit
import GameplayKit


class MovementComponent: GKComponent {

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

    private struct Constants {
        static let strength: CGFloat = 1000
        static let dt: CGFloat = 1 / 5000
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // check to see if the record entity is in the correct state (i.e. it is seeking a tapped record node)
        guard let intelligenceComponent = entity?.component(ofType: IntelligenceComponent.self),
            intelligenceComponent.stateMachine.currentState is SeekState,
            let targetEntity = entityToSeek else {
            return
        }

        // check the radius between its own entity and the entityToSeek, and apply the appropriate physics
        let renderComponent = self.renderComponent
        let physicsComponent = self.physicsComponent

        let deltaX = targetEntity.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let deltaY = targetEntity.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)

        let radius = distanceOf(x: deltaX, y: deltaY)

        let targetEntityMass = targetEntity.renderComponent.recordNode.physicsBody!.mass * Constants.strength * radius
        let entityMass = renderComponent.recordNode.physicsBody!.mass * Constants.strength * radius

        let unitVector = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)
        let force = (targetEntityMass * entityMass) / (radius * radius)
        let impulse = CGVector(dx: force * Constants.dt * unitVector.dx, dy: force * Constants.dt * unitVector.dy)

        physicsComponent.physicsBody.velocity = CGVector(dx: physicsComponent.physicsBody.velocity.dx + impulse.dx, dy: physicsComponent.physicsBody.velocity.dy + impulse.dy)
    }


    // MARK: Helpers

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
