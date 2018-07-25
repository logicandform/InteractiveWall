//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineDecadeLayout: NSCollectionViewFlowLayout {

    private let type: TimelineType = .decade

    private struct Constants {
        static let cellSize = CGSize(width: 192, height: 60)
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
        guard let item = source.events.index(of: event), let eventsForYear = source.eventsForYear[event.start], let heightIndex = eventsForYear.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: item, section: 0)
        let selected = source.selectedIndexes.contains(item)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let y = Constants.cellSize.height * CGFloat(heightIndex) + Constants.headerHeight
        let year = year ?? event.start
        let x = CGFloat((year - source.firstYear) * type.sectionWidth)
        let width = selected ? Constants.cellSize.width * 2 : Constants.cellSize.width
        attributes.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: Constants.cellSize.height))
        attributes.zIndex = selected ? event.start + source.lastYear : event.start
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
}
