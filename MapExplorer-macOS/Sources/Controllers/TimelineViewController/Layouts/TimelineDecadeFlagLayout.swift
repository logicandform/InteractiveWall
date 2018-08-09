//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineDecadeFlagLayout: NSCollectionViewFlowLayout {

    private let type: TimelineType = .decade
    private var attributesForEvent = [TimelineEvent: NSCollectionViewLayoutAttributes]()
    private var itemFrames = [CGRect]()

    private struct Constants {
        static let flagWidth: CGFloat = 180
        static let yearWidth: CGFloat = 192
        static let headerHeight: CGFloat = 20
        static let interFlagMargin: CGFloat = 5
        static let headerFlagMargin: CGFloat = 10
        static let infiniteScrollBuffer = 11
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
    }


    // MARK: Overrides

    /// Let's only try to calculate this once
    override func prepare() {
        super.prepare()
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return
        }

        itemFrames.removeAll()
        for year in (source.firstYear...source.lastYear) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let flagAttributes = flagAttributes(for: event, in: source) {
                        attributesForEvent[event] = flagAttributes
                        itemFrames.append(flagAttributes.frame)
                    }
                }
            }
        }
    }

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
                    if let attributes = attributesForEvent[event] {
                        layoutAttributes.append(attributes)
                    }
                }
            }
            // Append dividing line between last and first years
            if year == source.lastYear, let attributes = attributesForBorder(in: source) {
                layoutAttributes.append(attributes)
            }
            // Append attributes for supplimentary views
            if let headerAttributes = headerAttributes(year: year, in: source) {
                layoutAttributes.append(headerAttributes)
            }
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return nil
        }

        if let event = source.events.at(index: indexPath.item) {
            return attributesForEvent[event]
        } else if indexPath.item == source.events.count {
            return attributesForBorder(in: source)
        }

        return nil
    }


    // MARK: Helpers

    private func flagAttributes(for event: TimelineEvent, in source: TimelineDataSource, year: Int? = nil) -> NSCollectionViewLayoutAttributes? {
        guard let item = source.events.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let year = year ?? event.dates.startDate.year
        let x = CGFloat((year - source.firstYear) * type.sectionWidth)
        let flagHeight = TimelineFlagView.flagHeight(for: event)
        let height = flagMinY(forX: x, flagHeight: flagHeight) - Constants.headerHeight + Constants.interFlagMargin + flagHeight

        attributes.zIndex = Int(-height)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: Constants.headerHeight), size: CGSize(width: Constants.flagWidth, height: height))
        return attributes
    }

    private func headerAttributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let x = CGFloat(item * type.sectionWidth)
        let size = CGSize(width: Constants.yearWidth, height: Constants.headerHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }

    private func attributesForBorder(in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return nil
        }

        let item = source.events.count
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let x = CGFloat(source.years.count * type.sectionWidth)
        attributes.frame = CGRect(x: x, y: Constants.headerHeight, width: style.borderWidth, height: collectionView.frame.height)
        return attributes
    }

    private func flagMinY(forX x: CGFloat, flagHeight: CGFloat) -> CGFloat {
        let intersectingFrames = itemFrames.filter { $0.minX <= x && $0.maxX > x }
        let sortedFrames = intersectingFrames.sorted(by: { $0.origin.y < $1.origin.y })
        return sortedFrames.last?.maxY ?? Constants.headerHeight + Constants.headerFlagMargin
    }
}
