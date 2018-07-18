//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that enables an entity to seek a target node (i.e. a tapped node) and creates a gravitational attraction between the two entities.
*/

import Foundation
import SpriteKit
import GameplayKit


class MovementComponent: GKComponent {

    enum MovementState {
        case seekEntity(RecordEntity?)
        case moveToAppropriateLevel
    }

    /// The type of movement state that needs to be executed on the next update cycle
    var requestedMovementState: MovementState?

    /// The entity that this component's entity should seek
    var entityToSeek: RecordEntity?

    private var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A MovementComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }

    private var intelligenceComponent: IntelligenceComponent {
        guard let intelligenceComponent = entity?.component(ofType: IntelligenceComponent.self) else {
            fatalError("A MovementComponent's entity must have an IntelligenceComponent")
        }
        return intelligenceComponent
    }

    private var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity?.component(ofType: PhysicsComponent.self) else {
            fatalError("A MovementComponent's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    private struct Constants {
        static let strength: CGFloat = 1000
        static let dt: CGFloat = 1 / 5000
        static let distancePadding: CGFloat = -50
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        if let movementState = requestedMovementState {
            handleMovement(for: movementState)
        }
    }


    // MARK: Helpers

    private func handleMovement(for state: MovementState) {
        switch state {
        case .seekEntity(let entity):
            seek(entity)
        case .moveToAppropriateLevel:
            moveToAppropriateLevel()
        }
    }

    /// Applies appropriate physics that emulates a gravitational pull between this component's entity and the entity that it should seek
    private func seek(_ entityToSeek: RecordEntity?) {
        // check to see if the record entity is in the correct state (i.e. it is seeking a tapped record node)
        guard intelligenceComponent.stateMachine.currentState is SeekState, let targetNode = entityToSeek else {
            return
        }

        // check the radius between its own entity and the nodeToSeek, and apply the appropriate physics
        let renderComponent = self.renderComponent
        let physicsComponent = self.physicsComponent

        let deltaX = targetNode.renderComponent.recordNode.position.x - renderComponent.recordNode.position.x
        let deltaY = targetNode.renderComponent.recordNode.position.y - renderComponent.recordNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)

        let radius = distanceOf(x: deltaX, y: deltaY)

        let targetEntityMass = targetNode.physicsComponent.physicsBody.mass * Constants.strength * radius
        let entityMass = renderComponent.recordNode.physicsBody!.mass * Constants.strength * radius

        let unitVector = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)
        let force = (targetEntityMass * entityMass) / (radius * radius)
        let impulse = CGVector(dx: force * Constants.dt * unitVector.dx, dy: force * Constants.dt * unitVector.dy)

        physicsComponent.physicsBody.velocity = CGVector(dx: physicsComponent.physicsBody.velocity.dx + impulse.dx, dy: physicsComponent.physicsBody.velocity.dy + impulse.dy)
    }

    /// Applies appropriate physics that moves the entity to the appropriate higher level before entering next state and setting its bitMasks
    private func moveToAppropriateLevel() {
        guard let referenceNode = NodeBoundingManager.instance.nodeBoundingEntityForLevel[0]?.nodeBoundingRenderComponent.node,
            let entity = entity as? RecordEntity else {
            return
        }

        let renderComponent = self.renderComponent
        let physicsComponent = self.physicsComponent

        // find the unit vector from the distance between this component's entity and the center root node
        let deltaX = renderComponent.recordNode.position.x - referenceNode.position.x
        let deltaY = renderComponent.recordNode.position.y - referenceNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let distanceBetweenNodeAndCenter = distanceOf(x: deltaX, y: deltaY)
        let unitVector = CGVector(dx: displacement.dx / distanceBetweenNodeAndCenter, dy: displacement.dy / distanceBetweenNodeAndCenter)

        // find the difference in distance. This gives the total distance that is left to travel for the node
        guard let currentLevel = entity.levelState.currentLevel,
            let currentLevelBoundingEntityComponent = NodeBoundingManager.instance.nodeBoundingEntityForLevel[currentLevel]?.nodeBoundingRenderComponent,
            let currentLevelBoundingNode = currentLevelBoundingEntityComponent.node else {
            return
        }

        let r2 = currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < Constants.distancePadding {
            // enter SeekState and provide the appropriate bitmasks and entityToSeek for the MovementComponent
            entity.movementComponent.requestedMovementState = .seekEntity(entityToSeek)
            entity.intelligenceComponent.stateMachine.enter(SeekState.self)

            entity.physicsComponent.physicsBody.categoryBitMask = currentLevelBoundingNode.physicsBody!.categoryBitMask
            entity.physicsComponent.physicsBody.collisionBitMask = currentLevelBoundingNode.physicsBody!.collisionBitMask
            entity.physicsComponent.physicsBody.contactTestBitMask = currentLevelBoundingNode.physicsBody!.contactTestBitMask

        } else {
            // apply velocity
            physicsComponent.physicsBody.velocity = CGVector(dx: 200 * unitVector.dx, dy: 200 * unitVector.dy)
        }
    }

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
