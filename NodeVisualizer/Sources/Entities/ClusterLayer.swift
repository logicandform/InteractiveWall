//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class ClusterLayer: GKEntity {

    var renderComponent: LayerRenderComponent {
        guard let renderComponent = component(ofType: LayerRenderComponent.self) else {
            fatalError("A NodeBoundingEntity must have a LayerRenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    init(cluster: NodeCluster) {
        super.init()

        let renderComponent = LayerRenderComponent(cluster: cluster)
        addComponent(renderComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
