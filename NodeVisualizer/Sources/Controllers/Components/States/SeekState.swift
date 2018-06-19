//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SeekState: GKState {

    unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        entity.component(ofType: RecordAgent.self)?.behavior = entity.behaviorForCurrentMandate
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        //do periodic checks to see if it is within radius, then update its state to connected
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is ConnectedState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)

        entity.component(ofType: RecordAgent.self)?.behavior = nil
    }
}
