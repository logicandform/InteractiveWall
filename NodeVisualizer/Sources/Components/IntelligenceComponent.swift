//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A 'GKComponent' that provides an entity with its own designated 'GKStateMachine' for determining their actions.
*/

import Foundation
import SpriteKit
import GameplayKit


class IntelligenceComponent: GKComponent {

    private(set) var stateMachine: GKStateMachine
    private let initialStateClass: AnyClass


    init(states: [GKState]) {
        self.stateMachine = GKStateMachine(states: states)
        let firstState = states.first!
        self.initialStateClass = type(of: firstState)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        stateMachine.update(deltaTime: seconds)
    }


    func enterInitialState() {
        stateMachine.enter(initialStateClass)
    }
}
