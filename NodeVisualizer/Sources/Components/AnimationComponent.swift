//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


enum AnimationState {
    case scaleAndCenterToPoint(CGPoint)
    case scaleToLevelSize
}


/// A `GKComponent` that provides the actions used to move Record nodes on the screen.
class AnimationComponent: GKComponent {

    var requestedAnimationState: AnimationState?

    private struct Constants {
        static let moveToPointDuration: TimeInterval = 1.2
        static let scaleToDuration: TimeInterval = 1.2
    }


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

    private func runAnimationFor(_ animationState: AnimationState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch animationState {
        case .scaleAndCenterToPoint(let point):
            let moveToPointAction = SKAction.move(to: point, duration: Constants.moveToPointDuration)
            let scaleAction = SKAction.scale(to: scaleSize(), duration: Constants.scaleToDuration)
            let sequencedAction = SKAction.sequence([moveToPointAction, scaleAction])
            entity.animateTappedEntity(with: sequencedAction)
        case .scaleToLevelSize:
            let scaleAction = SKAction.scale(to: scaleSize(), duration: Constants.scaleToDuration)
            entity.scale(with: scaleAction)
        }
    }

    private func scaleSize() -> CGSize {
        guard let entity = entity as? RecordEntity, let currentLevel = entity.clusterLevel.currentLevel else {
            return .zero
        }

        var scaleSize: CGSize
        switch currentLevel {
        case -1:
            scaleSize = CGSize(width: 45, height: 45)
        case 0:
            scaleSize = CGSize(width: 40, height: 40)
        case 1:
            scaleSize = CGSize(width: 30, height: 30)
        case 2:
            scaleSize = CGSize(width: 25, height: 25)
        case 3:
            scaleSize = CGSize(width: 20, height: 20)
        case 4:
            scaleSize = CGSize(width: 15, height: 15)
        case 5:
            scaleSize = CGSize(width: 10, height: 10)
        default:
            return .zero
        }

        return scaleSize
    }
}
