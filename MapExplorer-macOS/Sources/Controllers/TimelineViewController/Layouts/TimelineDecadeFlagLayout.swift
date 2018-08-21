//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineDecadeFlagLayout: NSCollectionViewFlowLayout {

    private let type: TimelineType = .decade

    // Cached attributes for fast access
    private(set) var layersForYear = [Int: [Layer]]()
    private(set) var tailHeightForYear = [Int: CGFloat]()
    private var attributesForEvent = [TimelineEvent: NSCollectionViewLayoutAttributes]()
//    private var attributesForYear = [Int: [NSCollectionViewLayoutAttributes]]()
    private var tailAttributesForYear = [Int: NSCollectionViewLayoutAttributes]()

    // Intermediate state for calculating attributes
    private var flagFrameForEvent = [TimelineEvent: CGRect]()

    private struct Constants {
        static let yearWidth: CGFloat = 192
        static let headerHeight: CGFloat = 20
        static let headerOffset = 18
        static let interFlagMargin: CGFloat = 5
        static let headerFlagMargin: CGFloat = 3
        static let infiniteScrollBuffer = 11
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
    }


    // MARK: Overrides

    /// Let's only try to calculate this once in an init function? necessary?
    override func prepare() {
        super.prepare()
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return
        }

        flagFrameForEvent.removeAll()
        attributesForEvent.removeAll()
//        attributesForYear.removeAll()
        layersForYear.removeAll()
        tailHeightForYear.removeAll()

        let diagram = TailDiagram()

        // Fill tail diagram for events
        for year in (source.firstYear...source.lastYear) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    let start = CGFloat(event.dates.startDate.year) * Constants.yearWidth - CGFloat(source.firstYear) * Constants.yearWidth
                    let end = CGFloat(event.dates.endDate.year) * Constants.yearWidth - CGFloat(source.firstYear) * Constants.yearWidth
                    let line = Line(event: event, start: start, end: end)
                    if !line.width.isZero {
                        diagram.add(line)
                    }
                }
            }
        }

        // Add start and end markers for timeline events
        for year in (source.firstYear...source.lastYear) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    let start = CGFloat(event.dates.startDate.year) * Constants.yearWidth - CGFloat(source.firstYear) * Constants.yearWidth
                    let end = CGFloat(event.dates.endDate.year) * Constants.yearWidth - CGFloat(source.firstYear) * Constants.yearWidth
                    diagram.addMarkers(for: event, start: start, end: end)
                }
            }
        }

        // Cache the layers for each year for fast access
        for year in (source.firstYear...source.lastYear) {
            let start = CGFloat(year) * Constants.yearWidth - CGFloat(source.firstYear) * Constants.yearWidth
            let end = start + Constants.yearWidth
            let layers = diagram.layersBetween(a: start, b: end)
            layersForYear[year] = layers
            tailHeightForYear[year] = diagram.height(of: layers)
        }

        // Build cache of event and tail attributes
        for year in (source.firstYear...source.lastYear + Constants.infiniteScrollBuffer) {
            let yearInRange = (year - source.firstYear) % source.years.count + source.firstYear
            if let events = source.eventsForYear[yearInRange] {
                for event in events {
                    if year > source.lastYear {
                        event.timelinePositionDate.year = year
                    }
                    if let flagAttributes = flagAttributes(for: event, in: source, year: year) {
//                        if attributesForYear[year] != nil {
//                            attributesForYear[year]?.append(flagAttributes)
//                        } else {
//                            attributesForYear[year] = [flagAttributes]
//                        }
                        attributesForEvent[event] = flagAttributes

                    }
                }
            }
            // Don't create tails for years past the last year for now
            if let tailAttributes = tailAttributes(year: year, in: source) {
                tailAttributesForYear[year] = tailAttributes
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
//            if let attributesInYear = attributesForYear[year] {
//                for attributes in attributesInYear {
//                    layoutAttributes.append(attributes)
//                }
//            }
            let yearInRange = (year - source.firstYear) % source.years.count + source.firstYear
            if let events = source.eventsForYear[yearInRange] {
                for event in events {
                    if year > source.lastYear {
                        event.timelinePositionDate.year = year
                    }
                    if let attributes = attributesForEvent[event] {
                        layoutAttributes.append(attributes)
                    }
//                    } else if let attributes = attributesForEvent[event] {
//                        attributes.frame.origin.x = CGFloat((year - source.firstYear) * type.sectionWidth)
//                        layoutAttributes.append(attributes)
//                    }
                }
            }
            // Append timeline tails for each year
            if let tailAttributes = tailAttributesForYear[year] {
                layoutAttributes.append(tailAttributes)
            }
//            } else if let tailAttributes = tailAttributesForYear[yearInRange] {
//                tailAttributes.frame.origin.x = CGFloat((year - source.firstYear) * type.sectionWidth)
//                layoutAttributes.append(tailAttributes)
//            }
            // Append dividing line between last and first years
            if year == source.lastYear, let attributes = borderAttributes(in: source) {
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
//        guard let source = collectionView?.dataSource as? TimelineDataSource, let event = source.events.at(index: indexPath.item) else {
//            return nil
//        }
        guard let source = collectionView?.dataSource as? TimelineDataSource, let event = source.eventForHashValue[indexPath.item] else {
            return nil
        }

        return attributesForEvent[event]
    }


    // MARK: Helpers

    private func flagAttributes(for event: TimelineEvent, in source: TimelineDataSource, year: Int) -> NSCollectionViewLayoutAttributes? {
//        guard let item = source.events.index(of: event) else {
//            return nil
//        }

        source.eventForHashValue[event.hashValue] = event
        let indexPath = IndexPath(item: event.hashValue, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let x = CGFloat((year - source.firstYear) * type.sectionWidth)
        let flagHeight = TimelineFlagView.flagHeight(for: event)
        let flagFrame = frameForFlag(atX: x, size: CGSize(width: style.timelineFlagWidth, height: flagHeight), year: event.dates.startDate.year, in: source)
        flagFrameForEvent[event] = flagFrame
        let totalHeight = flagFrame.minY - Constants.headerHeight + flagHeight

        attributes.zIndex = Int(-totalHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: Constants.headerHeight), size: CGSize(width: style.timelineFlagWidth, height: totalHeight))
        return attributes
    }

    private func headerAttributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let x = CGFloat(item * type.sectionWidth - Constants.headerOffset)
        let size = CGSize(width: Constants.yearWidth, height: Constants.headerHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }

    private func borderAttributes(in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return nil
        }

        let indexPath = IndexPath(item: 0, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineBorderView.supplementaryKind, with: indexPath)
        let x = CGFloat(source.years.count * type.sectionWidth)
        attributes.frame = CGRect(x: x, y: Constants.headerHeight, width: style.timelineBorderWidth, height: collectionView.frame.height)
        return attributes
    }

    // Returns all tail attributes for a given year
    private func tailAttributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        let indexPath = IndexPath(item: year, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineTailView.supplementaryKind, with: indexPath)
        let x = CGFloat((year - source.firstYear) * type.sectionWidth)
        let y = Constants.headerHeight + Constants.headerFlagMargin
        let height = tailHeightForYear[year] ?? 0
        attributes.frame = CGRect(x: x, y: y, width: Constants.yearWidth, height: height)
        attributes.zIndex = -1000
        return attributes
    }

    /// Returns the lowest frame available at the given x position and size.
    private func frameForFlag(atX x: CGFloat, size: CGSize, year: Int, in source: TimelineDataSource) -> CGRect {
        let minY = Constants.headerHeight + style.timelineTailMargin
        let intersectingFrames = flagFrameForEvent.values.filter { $0.minX <= x && $0.maxX > x }
        var sortedFrames = intersectingFrames.sorted(by: { $0.minY < $1.minY })

        // If no underlying frames, place at minY
        guard let first = sortedFrames.first else {
            return CGRect(origin: CGPoint(x: x, y: minY), size: size)
        }

        // Check first spot
        if minY + size.height <= first.minY - Constants.interFlagMargin {
            return CGRect(origin: CGPoint(x: x, y: minY), size: size)
        }

        // Check all spaces between underlying frames
        for index in (1 ..< sortedFrames.count) {
            let last = sortedFrames[index - 1]
            let current = sortedFrames[index]

            // Check if new frame plus margins can fit between frames
            if last.maxY + size.height + Constants.interFlagMargin * 2 <= current.minY {
                return CGRect(origin: CGPoint(x: x, y: last.maxY + Constants.interFlagMargin), size: size)
            }
        }

        // Place new frame on to of last underlying frame
        let topY = sortedFrames.last!.maxY + Constants.interFlagMargin
        return CGRect(origin: CGPoint(x: x, y: topY), size: size)
    }
}
