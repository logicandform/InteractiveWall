//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


enum EntityState {
    case falling
    case tapped
    case seekCluster
    case seekLayer
    case panTapped

    var `class`: AnyClass {
        switch self {
        case .falling:
            return FallingState.self
        case .tapped:
            return TappedState.self
        case .seekCluster:
            return SeekTappedEntityState.self
        case .seekLayer:
            return SeekBoundingLevelNodeState.self
        case .panTapped:
            return TappedEntityPanState.self
        }
    }
}


/// A 'GKComponent' that provides an entity with its own designated 'GKStateMachine' for determining their actions.
class IntelligenceComponent: GKComponent {

    private(set) var stateMachine: GKStateMachine


    // MARK: Initializer

    init(for entity: RecordEntity) {
        let states = [
            FallingState(entity: entity),
            SeekTappedEntityState(entity: entity),
            SeekBoundingLevelNodeState(entity: entity),
            TappedState(entity: entity),
            TappedEntityPanState(entity: entity)
        ]
        self.stateMachine = GKStateMachine(states: states)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        stateMachine.update(deltaTime: seconds)
    }
}
