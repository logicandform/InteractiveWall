//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


final class TimelineControlsDataSource: NSObject, NSCollectionViewDataSource {

    var monthCollectionView: NSCollectionView?
    var yearCollectionView: NSCollectionView?
    var decadeCollectionView: NSCollectionView?
    let decades: [Int]
    private let years: [Int]
    private let lastYear = (Calendar.current.component(.year, from: Date()) / 10) * 10 + 10

    private struct Constants {
        static let visibleControlItems = 7
        static let controlItemWidth: CGFloat = 70
        static let firstYear = 1860
    }


    // MARK: Init

    override init() {
        years = Array(Constants.firstYear...lastYear)
        let roundedFirstYear = (Constants.firstYear / 10) * 10
        let roundedLastYear = (lastYear / 10) * 10 - 10
        let roundedYears = Array(roundedFirstYear...roundedLastYear)
        decades = roundedYears.filter { $0 % 10 == 0 }
        super.init()
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