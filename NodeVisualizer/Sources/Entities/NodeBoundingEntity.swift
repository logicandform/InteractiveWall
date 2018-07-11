//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingEntity: GKEntity {

    var nodeBoundingRenderComponent: NodeBoundingRenderComponent {
        guard let renderComponent = component(ofType: NodeBoundingRenderComponent.self) else {
            fatalError("A NodeBoundingEntity must have a NodeBoundingRenderComponent")
        }
        return renderComponent
    }

    override init() {
        super.init()

        let renderComponent = NodeBoundingRenderComponent()
        addComponent(renderComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
