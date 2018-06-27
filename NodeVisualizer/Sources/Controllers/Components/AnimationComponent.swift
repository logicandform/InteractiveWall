//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class AnimationComponent: GKComponent {

    var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("An AnimationComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }

    var intelligenceComponent: IntelligenceComponent {
        guard let intelligenceComponent = entity?.component(ofType: IntelligenceComponent.self) else {
            fatalError("An AnimationComponent's entity must have an IntelligenceComponent")
        }
        return intelligenceComponent
    }

    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity?.component(ofType: PhysicsComponent.self) else {
            fatalError("An AnimationComponent's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    var goToPoint: Bool = false

    private struct Constants {
        static let strength: CGFloat = 1000
        static let dt: CGFloat = 1 / 5000
    }


    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // check that entity is in the TappedState --> when moving towards center, entity should only be in TappedState
        guard intelligenceComponent.stateMachine.currentState is TappedState, goToPoint else {
            return
        }

        let renderComponent = self.renderComponent
        let physicsComponent = self.physicsComponent

        if let sceneFrame = renderComponent.recordNode.scene?.frame {
            let centerPoint = CGPoint(x: sceneFrame.width / 2, y: sceneFrame.height / 2)

            // check if the entity has reached the center point
            guard !renderComponent.recordNode.contains(centerPoint) else {
                physicsComponent.physicsBody.isDynamic = false
                return
            }

            let deltaX = centerPoint.x - renderComponent.recordNode.position.x
            let deltaY = centerPoint.y - renderComponent.recordNode.position.y
            let displacement = CGVector(dx: deltaX, dy: deltaY)

            let distance = distanceOf(x: deltaX, y: deltaY)
            let unitVector = CGVector(dx: displacement.dx / distance, dy: displacement.dy / distance)

            let pointMass = 0.2 * Constants.strength * distance
            let entityMass = 0.2 * Constants.strength * distance

            let force = (pointMass * entityMass) / (distance * distance)
            let impulse = CGVector(dx: force * Constants.dt * unitVector.dx, dy: force * Constants.dt * unitVector.dy)

            physicsComponent.physicsBody.velocity = CGVector(dx: physicsComponent.physicsBody.velocity.dx + impulse.dx, dy: physicsComponent.physicsBody.velocity.dy + impulse.dy)
        }
    }


    // MARK: Helpers

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }









}











