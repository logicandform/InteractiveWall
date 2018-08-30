//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


enum AnimationState {
    case move(CGPoint)
    case scale(CGSize)
    case fade(out: Bool)
}


/// A `GKComponent` that provides the actions used to move Record nodes on the screen.
class AnimationComponent: GKComponent {

    var requestedAnimationStates = [AnimationState]()


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        runAnimations(for: requestedAnimationStates)
    }


    // MARK: Helpers

    private func runAnimations(for states: [AnimationState]) {
        guard let entity = entity as? RecordEntity, !states.isEmpty else {
            return
        }

        let actions = states.map { action(for: $0) }
        let groupedAction = SKAction.group(actions)
        entity.perform(action: groupedAction)
        requestedAnimationStates.removeAll()
    }

    private func action(for state: AnimationState) -> SKAction {
        switch state {
        case .move(let point):
            return SKAction.move(to: point, duration: style.moveAnimationDuration)
        case .scale(let size):
            return SKAction.scale(to: size, duration: style.scaleAnimationDuration)
        case .fade(let out):
            if out {
                return SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
            } else {
                return SKAction.fadeIn(withDuration: style.fadeAnimationDuration)
            }
        }
    }
}
