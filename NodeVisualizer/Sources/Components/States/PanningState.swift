//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class PanningState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity

    private var levels: Int = 0

    private var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else {
            fatalError("A PanningState's entity must have a RenderComponent")
        }
        return renderComponent
    }


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        guard previousState is TappedState, let cluster = entity.cluster else {
            return
        }

        for entities in cluster.entitiesForLevel {
            for sibling in entities {
                sibling.hasCollidedWithBoundingNode = false
            }
        }

        levels = cluster.layerForLevel.count
        cluster.updateForPanningEntity()
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard let cluster = entity.cluster else {
            return
        }

        let currentRecordNodePosition = renderComponent.recordNode.position
        cluster.center = currentRecordNodePosition
        for (_, boundingNodeEntity) in cluster.layerForLevel {
            boundingNodeEntity.nodeBoundingRenderComponent.node?.position = currentRecordNodePosition
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)

        if let cluster = entity.cluster {
            cluster.select(entity)
        }
//        levels = 0
    }
}
