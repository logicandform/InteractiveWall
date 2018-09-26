//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineDecadeFlagLayout: NSCollectionViewFlowLayout {
    static let yearsPerScreen = 10
    static let yearWidth = Configuration.touchScreen.frameSize.width / CGFloat(yearsPerScreen) / 2
    static let infiniteScrollBuffer = yearsPerScreen + 1

    // Cached attributes for fast access
    private(set) var layersForYear = [Int: [Layer]]()
    private(set) var tailHeightForYear = [Int: CGFloat]()
    private var attributesForEvent = [TimelineEvent: NSCollectionViewLayoutAttributes]()
    private var tailAttributesForYear = [Int: NSCollectionViewLayoutAttributes]()

    // Intermediate state for calculating attributes
    private var flagFrameForEvent = [TimelineEvent: CGRect]()

    private struct Constants {
        static let interFlagMargin: CGFloat = 5
        static let headerFlagMargin: CGFloat = 3
        static let countTitleHeight: CGFloat = 20
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
    }

    override init() {
        super.init()
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
        layersForYear.removeAll()
        tailHeightForYear.removeAll()

        let diagram = TailDiagram()

        // Fill tail diagram with school events
        for year in (source.firstYear...source.lastYear + TimelineDecadeFlagLayout.infiniteScrollBuffer) {
            if let events = source.eventsForYear[year] {
                for event in events where event.type == .school {
                    if let endDate = event.dates.endDate {
                        let start = position(for: event.dates.startDate, in: source)
                        let end = position(for: endDate, in: source)
                        let line = Line(event: event, start: start, end: end)
                        diagram.add(line)
                    }
                }
            }
        }

        // Add start and end markers for timeline school events
        for year in (source.firstYear...source.lastYear + TimelineDecadeFlagLayout.infiniteScrollBuffer) {
            if let events = source.eventsForYear[year] {
                for event in events where event.type == .school {
                    if let endDate = event.dates.endDate {
                        let start = position(for: event.dates.startDate, in: source)
                        let end = position(for: endDate, in: source)
                        diagram.addMarkers(for: event, start: start, end: end)
                    }
                }
            }
        }

        // Cache the layers for each year for fast access
        for year in (source.firstYear...source.lastYear + TimelineDecadeFlagLayout.infiniteScrollBuffer) {
            let start = CGFloat(year) * TimelineDecadeFlagLayout.yearWidth - CGFloat(source.firstYear) * TimelineDecadeFlagLayout.yearWidth
            let end = start + TimelineDecadeFlagLayout.yearWidth
            let layers = diagram.layersBetween(a: start, b: end)
            layersForYear[year] = layers
            tailHeightForYear[year] = diagram.height(of: layers) + Constants.countTitleHeight
        }

        // Build cache of event and tail attributes
        for year in (source.firstYear...source.lastYear + TimelineDecadeFlagLayout.infiniteScrollBuffer) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let flagAttributes = flagAttributes(for: event, in: source, year: year) {
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

        let totalYears = source.lastYear - source.firstYear + TimelineDecadeFlagLayout.infiniteScrollBuffer
        let width = CGFloat(totalYears) * TimelineDecadeFlagLayout.yearWidth
        return CGSize(width: width, height: itemSize.height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return []
        }

        var layoutAttributes = [NSCollectionViewLayoutAttributes]()
        let minYear = source.firstYear + Int(rect.minX) / Int(TimelineDecadeFlagLayout.yearWidth)
        let maxYear = source.firstYear + Int(rect.maxX) / Int(TimelineDecadeFlagLayout.yearWidth)

        for year in (minYear...maxYear) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let attributes = attributesForEvent[event] {
                        layoutAttributes.append(attributes)
                    }
                }
            }
            // Append timeline tails for each year
            if let tailAttributes = tailAttributesForYear[year] {
                layoutAttributes.append(tailAttributes)
            }
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
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return nil
        }

        let event = source.events[indexPath.item]
        return attributesForEvent[event]
    }


    // MARK: Helpers

    private func flagAttributes(for event: TimelineEvent, in source: TimelineDataSource, year: Int) -> NSCollectionViewLayoutAttributes? {
        guard let index = source.events.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: index, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let x = position(for: event.dates.startDate, in: source)
        let flagHeight = TimelineFlagView.flagHeight(for: event)
        let flagFrame = frameForFlag(atX: x, size: CGSize(width: style.timelineItemWidth, height: flagHeight), year: event.dates.startDate.year, in: source)
        flagFrameForEvent[event] = flagFrame
        let totalHeight = flagFrame.minY - style.timelineHeaderHeight + flagHeight

        attributes.zIndex = Int(-totalHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: style.timelineHeaderHeight), size: CGSize(width: style.timelineItemWidth, height: totalHeight))
        return attributes
    }

    private func headerAttributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let x = CGFloat(item) * TimelineDecadeFlagLayout.yearWidth - style.timelineHeaderOffset
        let size = CGSize(width: TimelineDecadeFlagLayout.yearWidth, height: style.timelineHeaderHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }

    private func borderAttributes(in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return nil
        }

        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineBorderView.supplementaryKind, with: .zero)
        let x = CGFloat(source.years.count) * TimelineDecadeFlagLayout.yearWidth
        attributes.frame = CGRect(x: x, y: style.timelineHeaderHeight, width: style.timelineBorderWidth, height: collectionView.frame.height)
        return attributes
    }

    // Returns all tail attributes for a given year
    private func tailAttributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        let indexPath = IndexPath(item: year, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineTailView.supplementaryKind, with: indexPath)
        let x = CGFloat(year - source.firstYear) * TimelineDecadeFlagLayout.yearWidth
        let y = style.timelineHeaderHeight + Constants.headerFlagMargin
        let height = tailHeightForYear[year] ?? 0
        attributes.frame = CGRect(x: x, y: y, width: TimelineDecadeFlagLayout.yearWidth, height: height)
        attributes.zIndex = -1000
        return attributes
    }

    /// Returns the lowest frame available at the given x position and size.
    private func frameForFlag(atX x: CGFloat, size: CGSize, year: Int, in source: TimelineDataSource) -> CGRect {
        let minY = style.timelineHeaderHeight + style.timelineTailMargin
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

    /// Returns an x-position on the timeline for a given date
    private func position(for date: RecordDate, in source: TimelineDataSource) -> CGFloat {
        let xYear = (CGFloat(date.year) - CGFloat(source.firstYear)) * TimelineDecadeFlagLayout.yearWidth
        let xMonth = CGFloat(date.month) * TimelineDecadeFlagLayout.yearWidth / 12
        let xDay = date.day * TimelineDecadeFlagLayout.yearWidth / 12

        return round(xYear + xMonth + xDay)
    }
}
