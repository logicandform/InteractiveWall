//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class RelatedEntityManager {

    // 2D array where the inner array is the array of related items

    let maxLevel = 5

    private(set) var entitiesInLevel = [[RecordEntity]]()


    func relatedEntities(for entities: [RecordEntity], toLevel level: Int = 0) {

        if level > maxLevel, entities.isEmpty {
            return
        }

        for entity in entities {
            entitiesInLevel[level] += entity.relatedEntities
        }

        relatedEntities(for: entitiesInLevel[level], toLevel: level + 1)


        // edge cases to consider:
        // maxLevel should contain all of the remaining descendants that otherwise would have gone to level 6, 7, 8, etc
        // the related entities in one level should not contain entities that are already part of another level

    }











}
