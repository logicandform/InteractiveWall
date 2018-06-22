//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class TappedState: GKState {

    private(set) unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        let relatedEntities = getRelatedEntites()

        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        for case let relatedEntity as RecordEntity in relatedEntities {
            relatedEntity.movementComponent.entityToSeek = entity
            relatedEntity.intelligenceComponent.stateMachine.enter(SeekState.self)
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SeekState.Type
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }


    private func getRelatedEntites() -> [GKEntity] {
        let record = entity.renderComponent.recordNode.record
        guard let relatedRecords = TestingEnvironment.instance.relatedRecordsForRecord[record] else {
            return []
        }

        let relatedEntities = entity.manager.entities(for: Array(relatedRecords))
        return relatedEntities
    }



}











