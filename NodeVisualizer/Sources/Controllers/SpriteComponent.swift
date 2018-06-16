//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SpriteComponent: GKComponent {

    private(set) var recordNode: RecordNode


    init(record: RecordDisplayable) {
        self.recordNode = RecordNode(record: record)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func applyInitialAnimation(with force: CGVector) {
        let scaledForceX = force.dx * 0.05
        let scaledForceY = force.dy * 0.05
        let applyForceAction = SKAction.applyForce(CGVector(dx: scaledForceX, dy: scaledForceY), duration: 0.1)
        recordNode.run(applyForceAction)
    }
}
