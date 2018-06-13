//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class RecordEntity: GKEntity {

    init(record: RecordDisplayable) {
        super.init()
        
        let spriteComponent = SpriteComponent(record: record)
        addComponent(spriteComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



}











