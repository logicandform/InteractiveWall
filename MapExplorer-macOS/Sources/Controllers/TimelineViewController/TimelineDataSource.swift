//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class TimelineDataSource: NSObject, NSCollectionViewDataSource {

    var type = TimelineType.decade
    var selectedIndexes = Set<Int>()
    let firstYear = Constants.firstYear
    let lastYear = Constants.lastYear
    let years = Array(Constants.firstYear...Constants.lastYear)
    private(set) var events = [TimelineEvent]()
    private(set) var eventsForYear = [Int: [TimelineEvent]]()
    private(set) var eventsForMonth = [Int: [Month: [TimelineEvent]]]()

    private struct Constants {
        static let screenWidth = 1920
        static let firstYear = 1860
        static let lastYear = 1980
    }


    // MARK: Init

    override init() {
        super.init()
        setupEvents()
//        let years = (Constants.firstYear...Constants.lastYear).count
//        var countForCounts = [Int: Int]()
//        var countForYear = [Int: Int]()
//        for year in (Constants.firstYear...Constants.lastYear) {
//            let count = eventsForYear[year]?.count ?? 0
//            if !count.isZero {
//                countForYear[year] = count
//                print("\(count) schools starting in year: \(year).")
//            }
//            if let current = countForCounts[count] {
//                countForCounts[count] = current + 1
//            } else {
//                countForCounts[count] = 1
//            }
//        }
//
//        for (size, count) in countForCounts.sorted(by: { $0.0 < $1.0 }) {
//            print("There are \(count) years with size \(size).")
//        }
//
//        for (size, count) in countForCounts.sorted(by: { $0.0 < $1.0 }) {
//            let percent = Double(count) / Double(years)
//            print("Years with size: \(size) make up \(percent) of all the years.")
//        }
//
//        print("\(countForYear.keys.count) years out of \(years) have at least one school start.")
//
//        let sortedYears = countForYear.keys.sorted()
//        for (index, year) in sortedYears.enumerated() {
//            let nextIndex = index + 1
//            if nextIndex != sortedYears.count {
//                let nextYear = sortedYears[nextIndex]
//                let distanceToNextYear = nextYear - year
//                print("\(year) has a \(distanceToNextYear) year gap until next school occurance.")
//            } else {
//                print("\(year) is the last year.")
//            }
//        }
    }


    // MARK: Helpers

    func events(in range: [Int]) -> Int {
        return range.reduce(0) { return $0 + (eventsForYear[$1]?.count ?? 0) }
    }


    // MARK: Setup

    private func setupEvents() {
        events = TimelineEvent.allEvents()
        for event in events {
            // Add to year dictionary
            if eventsForYear[event.start] != nil {
                eventsForYear[event.start]!.append(event)
            } else {
                eventsForYear[event.start] = [event]
            }

            // Add to month dictionary
            if eventsForMonth[event.start] != nil {
                if eventsForMonth[event.start]![event.startMonth] != nil {
                    eventsForMonth[event.start]![event.startMonth]!.append(event)
                } else {
                    eventsForMonth[event.start]![event.startMonth] = [event]
                }
            } else {
                eventsForMonth[event.start] = [event.startMonth: [event]]
            }
        }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return events.count + years.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let timelineItem = collectionView.makeItem(withIdentifier: TimelineItemView.identifier, for: indexPath) as? TimelineItemView, let attributes = collectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) else {
            return NSCollectionViewItem()
        }

        timelineItem.event = events[indexPath.item]
        timelineItem.set(selected: selectedIndexes.contains(indexPath.item % years.count), with: type, zIndex: CGFloat(attributes.zIndex))
        return timelineItem
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        guard let headerView = collectionView.makeSupplementaryView(ofKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier, for: indexPath) as? TimelineHeaderView else {
            return NSView()
        }

        switch type {
        case .month:
            let month = Month.allValues[indexPath.item % Month.allValues.count]
            headerView.textLabel.stringValue = month.abbreviation
        case .year, .decade, .century:
            let year = firstYear + (indexPath.item % years.count)
            headerView.textLabel.stringValue = year.description
        }

        return headerView
    }
}
