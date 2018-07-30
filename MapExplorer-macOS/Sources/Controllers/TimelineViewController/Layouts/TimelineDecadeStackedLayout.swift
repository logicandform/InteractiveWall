//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineDecadeStackedLayout: NSCollectionViewFlowLayout {

    private let type: TimelineType = .decade
    private var frameForEventInRow = [Int: CGRect]()
    private var frameForEvent = [TimelineEvent: CGRect]()

    private struct Constants {
        static let cellSize = CGSize(width: 192, height: 30)
        static let headerHeight: CGFloat = 20
        static let infiniteScrollBuffer = 11
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
    }


    // MARK: Overrides

    override var collectionViewContentSize: NSSize {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return .zero
        }

        let totalYears = source.lastYear - source.firstYear + Constants.infiniteScrollBuffer
        let width = CGFloat(totalYears * type.sectionWidth)
        return CGSize(width: width, height: itemSize.height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return []
        }

        var layoutAttributes = [NSCollectionViewLayoutAttributes]()
        let minYear = source.firstYear + Int(rect.minX) / type.sectionWidth
        let maxYear = source.firstYear + Int(rect.maxX) / type.sectionWidth

        for year in (minYear...maxYear) {
            // Append attributes for items
            let yearInRange = (year - source.firstYear) % source.years.count + source.firstYear
            if let events = source.eventsForYear[yearInRange] {
                for event in events {
                    if let attributes = attributes(for: event, in: source, year: year) {
                        layoutAttributes.append(attributes)
                    }
                }
            }
            // Append attributes for supplimentary views
            if let attributes = attributes(year: year, in: source) {
                layoutAttributes.append(attributes)
            }
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let source = collectionView?.dataSource as? TimelineDataSource, let event = source.events.at(index: indexPath.item) else {
            return nil
        }

        return attributes(for: event, in: source)
    }


    // MARK: Helpers

    private func attributes(for event: TimelineEvent, in source: TimelineDataSource, year: Int? = nil) -> NSCollectionViewLayoutAttributes? {
        guard let item = source.events.index(of: event), let eventsForYear = source.eventsForYear[event.dates.startDate.year], let heightIndex = eventsForYear.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: item, section: 0)
        let selected = source.selectedIndexes.contains(item)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
//        let y = Constants.cellSize.height * CGFloat(heightIndex) + Constants.headerHeight
        let year = year ?? event.dates.startDate.year
        let x = CGFloat((year - source.firstYear) * type.sectionWidth)
        let row = rowFor(event: event, xPosition: x)
        let y = Constants.cellSize.height * CGFloat(row) + Constants.headerHeight
        let width = CGFloat((event.dates.endDate.year - event.dates.startDate.year) + 1) * Constants.cellSize.width
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: Constants.cellSize.height))
        attributes.frame = frame
        attributes.zIndex = selected ? event.dates.startDate.year + source.lastYear : event.dates.startDate.year
        frameForEventInRow[row] = frame
        frameForEvent[event] = frame
        return attributes
    }

    private func attributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let x = CGFloat(item * type.sectionWidth)
        let size = CGSize(width: Constants.cellSize.width, height: Constants.headerHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }

    private func eventExistsAt(xPosition x: CGFloat, row: Int) -> Bool {
        guard let frame = frameForEventInRow[row] else {
            return false
        }

        return frame.minX <= x && frame.maxX >= x
    }

    private func rowFor(event: TimelineEvent, xPosition x: CGFloat) -> Int {
        if let frame = frameForEvent[event] {
            return Int((frame.origin.y - Constants.headerHeight) / Constants.cellSize.height)
        }

        var row = 0
        while eventExistsAt(xPosition: x, row: row) {
            row += 1
        }

        return row
    }
}
