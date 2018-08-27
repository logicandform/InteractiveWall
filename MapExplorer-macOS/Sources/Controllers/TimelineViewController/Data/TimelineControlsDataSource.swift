//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


final class TimelineControlsDataSource: NSObject, NSCollectionViewDataSource {

    var monthCollectionView: NSCollectionView?
    var yearCollectionView: NSCollectionView?
    var decadeCollectionView: NSCollectionView?
    var firstYear: Int!
    var lastYear: Int!
    var years = [Int]()
    var decades = [Int]()

    private struct Constants {
        static let visibleControlItems = 7
        static let controlItemWidth: CGFloat = 70
    }


    // MARK: API

    func set(firstYear: Int, lastYear: Int) {
        self.firstYear = firstYear
        self.lastYear = lastYear
        years = Array(firstYear...lastYear)
        let decadeAdjustedLastYear = lastYear - 10
        let truncatedYears = Array(firstYear...decadeAdjustedLastYear)
        decades = truncatedYears.filter { $0 % 10 == 0 }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case monthCollectionView:
            return Month.allValues.count + Constants.visibleControlItems
        case yearCollectionView:
            return years.count + Constants.visibleControlItems
        case decadeCollectionView:
            return decades.count + Constants.visibleControlItems
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch collectionView {
        case monthCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let month = Month.allValues.at(index: indexPath.item % Month.allValues.count)
                controlItemView.title = month?.abbreviation
                return controlItemView
            }
        case yearCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let year = years.at(index: indexPath.item % years.count)
                controlItemView.title = year?.description
                return controlItemView
            }
        case decadeCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let decade = decades.at(index: indexPath.item % decades.count)
                controlItemView.title = decade?.description
                return controlItemView
            }
        default:
            break
        }

        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        guard let borderView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineBorderView.identifier, for: indexPath) as? TimelineBorderView else {
            return NSView()
        }

        return borderView
    }
}
