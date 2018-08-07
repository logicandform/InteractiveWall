//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


enum AnimationState {
    case goToPoint(CGPoint)
}


/// A `GKComponent` that provides the actions used to move Record nodes on the screen.
class AnimationComponent: GKComponent {

    var requestedAnimationState: AnimationState?


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // if an animation has been requested and the entity is in the TappedState, then run the animation
        if let animationState = requestedAnimationState {
            requestedAnimationState = nil
            runAnimationFor(animationState)
        }
    }


    // MARK: Helpers

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }

    private func runAnimationFor(_ animationState: AnimationState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch animationState {
        case .goToPoint(let point):
            let moveAction = SKAction.move(to: point, duration: 1.2)
            entity.run(action: moveAction)
        }
    }
}
