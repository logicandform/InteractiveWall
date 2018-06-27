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

        entity.physicsComponent.physicsBody.isDynamic = false

        // run animation to go to center of screen, set the field bit mask
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1
        let action = SKAction.move(to: CGPoint(x: entity.renderComponent.recordNode.scene!.frame.size.width / 2, y: entity.renderComponent.recordNode.scene!.frame.size.height / 2), duration: 4)

        entity.renderComponent.recordNode.run(action)

//        entity.physicsComponent.physicsBody.isDynamic = false
//
        // iterate through each related entity to this selected entity && enter the seeking state for each of those related entities
        let relatedEntities = getRelatedEntites()
        entity.relatedEntities = relatedEntities

        for case let relatedEntity in relatedEntities {
            relatedEntity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1
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


    // MARK: Helpers

    private func getRelatedEntites() -> [RecordEntity] {
        let record = entity.renderComponent.recordNode.record
        guard let relatedRecords = TestingEnvironment.instance.relatedRecordsForRecord[record] else {
            return []
        }

        let relatedEntities = entity.manager.entities(for: Array(relatedRecords)).compactMap({ $0 as? RecordEntity })

        return relatedEntities
    }
}
