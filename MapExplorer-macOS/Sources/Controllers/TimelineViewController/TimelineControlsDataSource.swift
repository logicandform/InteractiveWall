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
            return years.count + Constants.visibleControlItems + 1
        case decadeCollectionView:
            return decades.count + Constants.visibleControlItems + 1
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
            if indexPath.item == years.count, let border = collectionView.makeItem(withIdentifier: TimelineBorder.identifier, for: indexPath) as? TimelineBorder {
                let x = CGFloat(years.count) * Constants.controlItemWidth
                let frame = CGRect(x: x, y: collectionView.frame.height / 4, width: style.borderWidth, height: collectionView.frame.height / 2)
                border.set(frame: frame)
                return border
            } else if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let itemIndex = indexPath.item >= years.count ? indexPath.item - 1 : indexPath.item
                let year = years.at(index: itemIndex % years.count)
                controlItemView.title = year?.description
                return controlItemView
            }
        case decadeCollectionView:
            if indexPath.item == decades.count, let border = collectionView.makeItem(withIdentifier: TimelineBorder.identifier, for: indexPath) as? TimelineBorder {
                let x = CGFloat(decades.count) * Constants.controlItemWidth
                let frame = CGRect(x: x, y: collectionView.frame.height / 4, width: style.borderWidth, height: collectionView.frame.height / 2)
                border.set(frame: frame)
                return border
            } else if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let itemIndex = indexPath.item >= decades.count ? indexPath.item - 1 : indexPath.item
                let decade = decades.at(index: itemIndex % decades.count)
                controlItemView.title = decade?.description
                return controlItemView
            }
        default:
            break
        }

        return NSCollectionViewItem()
    }
}
