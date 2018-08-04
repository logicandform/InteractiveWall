//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that provides different types of physics movement for the entity.
*/

import Foundation
import SpriteKit
import GameplayKit


enum MovementState {
    case seekEntity(RecordEntity?)
    case moveToAppropriateLevel
}


class MovementComponent: GKComponent {

    var cluster: NodeCluster?

    /// The type of movement state that needs to be executed on the next update cycle
    var requestedMovementState: MovementState?


    // MARK: Components

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
        static let distancePadding: CGFloat = -10
        static let speed: CGFloat = 200
    }


    // MARK: API

    func reset() {
        requestedMovementState = nil
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
        guard intelligenceComponent.stateMachine.currentState is SeekTappedEntityState, let targetNode = entityToSeek else {
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
        guard intelligenceComponent.stateMachine.currentState is SeekBoundingLevelNodeState,
            let referenceNode = cluster?.layerForLevel[0]?.nodeBoundingRenderComponent.node,
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

        var unitVector: CGVector
        // check whether the entity is currently in the center in order to apply a non-zero unit vector for movement
        if distanceBetweenNodeAndCenter > 0 {
            unitVector = CGVector(dx: displacement.dx / distanceBetweenNodeAndCenter, dy: displacement.dy / distanceBetweenNodeAndCenter)
        } else {
            unitVector = CGVector(dx: 0.5, dy: 0)
        }

        // find the difference in distance. This gives the total distance that is left to travel for the node
        guard let currentLevel = entity.clusterLevel.currentLevel,
            let currentLevelBoundingEntityComponent = cluster?.layerForLevel[currentLevel]?.nodeBoundingRenderComponent else {
            return
        }

        let r2 = currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < Constants.distancePadding {
            // enter SeekState and provide the appropriate bitmasks and entityToSeek for the MovementComponent
            physicsComponent.setBitMasks(forLevel: currentLevel)
            requestedMovementState = .seekEntity(cluster?.selectedEntity)
            intelligenceComponent.stateMachine.enter(SeekTappedEntityState.self)
        } else {
            // apply velocity
            physicsComponent.physicsBody.velocity = CGVector(dx: Constants.speed * unitVector.dx, dy: Constants.speed * unitVector.dy)
        }
    }

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
