//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class NodeBoundingEntity: GKEntity, NodeBoundingRenderComponentDelegate {

    var nodeBoundingRenderComponent: NodeBoundingRenderComponent {
        guard let renderComponent = component(ofType: NodeBoundingRenderComponent.self) else {
            fatalError("A NodeBoundingEntity must have a NodeBoundingRenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    override init() {
        super.init()

        let renderComponent = NodeBoundingRenderComponent()
        addComponent(renderComponent)
        renderComponent.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: NodeBoundingRenderComponentDelegate

    func changeInRadiusNotification(withRadius radius: CGFloat) {
        if let boundingNode = nodeBoundingRenderComponent.node {
            let boundingNodeRadiusWidth = boundingNode.calculateAccumulatedFrame().width / 2
            let boundingNodeRadiusHeight = boundingNode.calculateAccumulatedFrame().height / 2
            let boundingNodeRadius = boundingNodeRadiusWidth > boundingNodeRadiusHeight ? boundingNodeRadiusWidth : boundingNodeRadiusHeight

            let scale = radius / boundingNodeRadius
            boundingNode.setScale(scale)
        }
    }
}
