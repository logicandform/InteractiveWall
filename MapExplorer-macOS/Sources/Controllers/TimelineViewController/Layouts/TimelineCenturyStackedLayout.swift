//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineCenturyStackedLayout: NSCollectionViewFlowLayout {

    let type: TimelineType = .century

    private var attributesForEvent = [TimelineEvent: NSCollectionViewLayoutAttributes]()
    private var frameForEventInRow = [Int: CGRect]()

    private struct Constants {
        static let cellSize = CGSize(width: 160, height: 24)
        static let headerHeight: CGFloat = 20
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
    }


    // MARK: Overrides

    override func prepare() {
        super.prepare()
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return
        }

        for year in (source.firstYear...source.lastYear) {
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let attributes = attributes(for: event, in: source) {
                        attributesForEvent[event] = attributes
                    }
                }
            }
        }
    }

    override var collectionViewContentSize: NSSize {
        return CGSize(width: 1920, height: itemSize.height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return []
        }

        var layoutAttributes = [NSCollectionViewLayoutAttributes]()
        let minYear = source.firstYear + Int(rect.minX) / type.layoutWidth
        let maxYear = source.firstYear + Int(rect.maxX) / type.layoutWidth

        for year in (minYear...maxYear) {
            // Append attributes for items
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let attributes = attributesForEvent[event] {
                        layoutAttributes.append(attributes)
                    }
                }
            }
            // Append attributes for supplimentary views
            //            if let attributes = attributes(year: year, in: source) {
            //                layoutAttributes.append(attributes)
            //            }
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let source = collectionView?.dataSource as? TimelineDataSource, let event = source.events.at(index: indexPath.item) else {
            return nil
        }

        return attributesForEvent[event]
    }


    // MARK: Helpers

    private func attributes(for event: TimelineEvent, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        guard let item = source.events.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: item, section: 0)
        let selected = source.selectedIndexes.contains(item)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let x = CGFloat((event.start - source.firstYear) * type.layoutWidth)
        let row = rowFor(xPosition: x)
        let y = Constants.cellSize.height * CGFloat(row) + Constants.headerHeight
        let width = selected ? Constants.cellSize.width * 2 : Constants.cellSize.width
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: Constants.cellSize.height))
        attributes.frame = frame
        attributes.zIndex = selected ? event.start + source.lastYear : event.start
        frameForEventInRow[row] = frame
        return attributes
    }

    private func attributes(year: Int, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let x = CGFloat(item * type.layoutWidth)
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

    private func rowFor(xPosition x: CGFloat) -> Int {
        var row = 0
        while eventExistsAt(xPosition: x, row: row) {
            row += 1
        }

        return row
    }
}
