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
        static let scaleToDuration: TimeInterval = 1.3
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

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
            let groupedAction = SKAction.group([moveToPointAction, scaleAction])
            entity.animateTappedEntity(with: groupedAction)
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
            scaleSize = style.selectedNodeSize
        case 0:
            scaleSize = style.levelZeroNodeSize
        case 1:
            scaleSize = style.levelOneNodeSize
        case 2:
            scaleSize = style.levelTwoNodeSize
        case 3:
            scaleSize = style.levelThreeNodeSize
        case 4:
            scaleSize = style.levelFourNodeSize
        case 5:
            scaleSize = style.levelFiveNodeSize
        default:
            return .zero
        }

        return scaleSize
    }
}
