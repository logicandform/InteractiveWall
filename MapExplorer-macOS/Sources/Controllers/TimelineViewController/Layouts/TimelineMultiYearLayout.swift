//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineMultiYearLayout: NSCollectionViewFlowLayout {

    private let layoutWidth = 240

    private struct Constants {
        static let cellSize = CGSize(width: 240, height: 60)
        static let headerHeight: CGFloat = 20
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

        let totalYears = source.lastYear - source.firstYear + 1
        let width = CGFloat(totalYears * layoutWidth)
        return CGSize(width: width, height: itemSize.height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return []
        }

        var layoutAttributes = [NSCollectionViewLayoutAttributes]()
        let minYear = source.firstYear + Int(rect.minX) / layoutWidth
        let maxYear = source.firstYear + Int(rect.maxX) / layoutWidth

        for year in (minYear...maxYear) {
            // Append attributes for items
            if let events = source.eventsForYear[year] {
                for event in events {
                    if let attributes = attributes(for: event, in: source) {
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

    private func attributes(for event: TimelineEvent, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        guard let item = source.events.index(of: event), let eventsForYear = source.eventsForYear[event.start], let heightIndex = eventsForYear.index(of: event) else {
            return nil
        }

        let indexPath = IndexPath(item: item, section: 0)
        let selected = source.selectedIndexes.contains(item)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let y = Constants.cellSize.height * CGFloat(heightIndex) + Constants.headerHeight
        let x = CGFloat((event.start - source.firstYear) * layoutWidth)
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
        let x = CGFloat(item * layoutWidth)
        let size = CGSize(width: Constants.cellSize.width, height: Constants.headerHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }
}
