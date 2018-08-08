//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedEntityPanState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        if previousState is TappedState, let cluster = entity.cluster {
            cluster.updateLayerLevels(forPan: true)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard let cluster = entity.cluster else {
            return
        }

        // TODO: UBC-542
        // update velocity of all contacted physics bodies
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)

        if let cluster = entity.cluster {
            cluster.updateLayerLevels(forPan: false)
        }
    }
}
