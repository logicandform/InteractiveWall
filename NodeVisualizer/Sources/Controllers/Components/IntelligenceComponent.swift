//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class IntelligenceComponent: GKComponent {

    let stateMachine: GKStateMachine
    let initialStateClass: AnyClass


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
