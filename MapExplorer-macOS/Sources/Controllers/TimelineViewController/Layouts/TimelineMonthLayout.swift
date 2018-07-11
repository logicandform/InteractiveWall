//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineMonthLayout: NSCollectionViewFlowLayout {

    private struct Constants {
//        static let monthWidth = 1920
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
        let totalMonths = totalYears * 12
        let width = CGFloat(totalMonths * style.monthLayoutMonthWidth)
        return CGSize(width: width, height: itemSize.height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        guard let source = collectionView?.dataSource as? TimelineDataSource else {
            return []
        }

        var layoutAttributes = [NSCollectionViewLayoutAttributes]()
        let yearWidth = style.monthLayoutMonthWidth * 12
        var year = source.firstYear + Int(rect.minX) / yearWidth
        let minMonth = Int(rect.minX) / style.monthLayoutMonthWidth % Month.allValues.count
        let maxMonth = Int(rect.maxX) / style.monthLayoutMonthWidth % Month.allValues.count

        let yearMax = maxMonth < minMonth ? 11 : maxMonth
        for monthIndex in (minMonth...yearMax) {
            let month = Month.allValues[monthIndex]

            // Append attributes for items
            if let events = source.eventsForMonth[year]?[month] {
                for event in events {
                    if let attributes = attributes(for: event, in: source) {
                        layoutAttributes.append(attributes)
                    }
                }
            }
            // Append attributes for supplimentary views
            if let attributes = attributes(year: year, month: month, in: source) {
                layoutAttributes.append(attributes)
            }
        }

        if maxMonth < minMonth {
            year += 1
            for monthIndex in (0...minMonth) {
                let month = Month.allValues[monthIndex]

                // Append attributes for items
                if let events = source.eventsForMonth[year]?[month] {
                    for event in events {
                        if let attributes = attributes(for: event, in: source) {
                            layoutAttributes.append(attributes)
                        }
                    }
                }
                // Append attributes for supplimentary views
                if let attributes = attributes(year: year, month: month, in: source) {
                    layoutAttributes.append(attributes)
                }
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
        let yearWidth = style.monthLayoutMonthWidth * 12
        let yearStart = CGFloat((event.start - source.firstYear) * yearWidth)
        let x = yearStart + CGFloat(event.startMonth.rawValue * style.monthLayoutMonthWidth)
        let width = selected ? Constants.cellSize.width * 2 : Constants.cellSize.width
        attributes.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: Constants.cellSize.height))
        attributes.zIndex = selected ? event.start + source.lastYear : event.start
        return attributes
    }

    private func attributes(year: Int, month: Month, in source: TimelineDataSource) -> NSCollectionViewLayoutAttributes? {
        if year < source.firstYear {
            return nil
        }

        let item = year - source.firstYear
        let indexPath = IndexPath(item: month.rawValue, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, with: indexPath)
        let yearWidth = style.monthLayoutMonthWidth * 12
        let yearStart = CGFloat(item * yearWidth)
        let x = yearStart + CGFloat(month.rawValue * style.monthLayoutMonthWidth)
        let size = CGSize(width: CGFloat(style.monthLayoutMonthWidth), height: Constants.headerHeight)
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: size)
        return attributes
    }
}
