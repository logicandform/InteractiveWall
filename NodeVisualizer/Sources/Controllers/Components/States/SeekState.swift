//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SeekState: GKState {

    private(set) unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        entity.physicsComponent.physicsBody.friction = 1
        entity.physicsComponent.physicsBody.linearDamping = 1
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SeekState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }
}
