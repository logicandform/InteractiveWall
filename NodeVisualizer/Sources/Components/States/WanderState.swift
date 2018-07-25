//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    This is the initial state for the RecordEntity. A RecordEntity also enters this state when it needs to 'reset' to its bare standard components and properties. 
 */

import Foundation
import SpriteKit
import GameplayKit


class WanderState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity

    private var movementComponent: MovementComponent {
        guard let movementComponent = entity.component(ofType: MovementComponent.self) else {
            fatalError("A WanderState's entity must have a MovementComponent")
        }
        return movementComponent
    }

    private var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else {
            fatalError("A WanderState's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        movementComponent.reset()
        physicsComponent.reset()
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }
}
