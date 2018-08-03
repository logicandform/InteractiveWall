//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


final class TimelineDataSource: NSObject, NSCollectionViewDataSource {

    var type = TimelineType.decade
    var selectedIndexes = [Int]()
    let firstYear = Constants.firstYear
    var lastYear = (Calendar.current.component(.year, from: Date()) / 10) * 10 + 10
    var years: [Int]
    var records = [Record]() {
        didSet {
            setupEvents(for: records)
        }
    }

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
        years = Array(Constants.firstYear...lastYear)
        super.init()
    }


    // MARK: API

    func events(in range: [Int]) -> Int {
        return range.reduce(0) { return $0 + (eventsForYear[$1]?.count ?? 0) }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch type {
        case .month:
            return events.count + (years.count * 12)
        case .year, .decade, .century:
            return events.count + years.count
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.item == events.count, let border = collectionView.makeItem(withIdentifier: TimelineBorder.identifier, for: indexPath) as? TimelineBorder, let attributes = collectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) {
            border.set(frame: attributes.frame)
            return border
        } else if let timelineItem = collectionView.makeItem(withIdentifier: TimelineItemView.identifier, for: indexPath) as? TimelineItemView, let attributes = collectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) {
            timelineItem.event = events[indexPath.item]
            timelineItem.set(selected: selectedIndexes.contains(indexPath.item % years.count), with: type, attributes: attributes)
            return timelineItem
        }

        return NSCollectionViewItem()
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


    // MARK: Helpers

    private func setupEvents(for records: [Record]) {
        for record in records {
            if let dates = record.dates {
                let event = TimelineEvent(id: record.id, type: record.type, title: record.title, dates: dates)
                events.append(event)

                // Add to year dictionary
                if eventsForYear[event.dates.startDate.year] != nil {
                    eventsForYear[event.dates.startDate.year]!.append(event)
                } else {
                    eventsForYear[event.dates.startDate.year] = [event]
                }

                // Add to month dictionary
                if eventsForMonth[event.dates.startDate.year] != nil, Month(rawValue: event.dates.startDate.month) != nil {
                    if eventsForMonth[event.dates.startDate.year]![Month(rawValue: event.dates.startDate.month)!] != nil {
                        eventsForMonth[event.dates.startDate.year]![Month(rawValue: event.dates.startDate.month)!]!.append(event)
                    } else {
                        eventsForMonth[event.dates.startDate.year]![Month(rawValue: event.dates.startDate.month)!] = [event]
                    }
                } else {
                    eventsForMonth[event.dates.startDate.year] = [Month(rawValue: event.dates.startDate.month)!: [event]]
                }
            }
        }

        printAnalytics()
    }

    private func printAnalytics() {
        let yearCount = years.count
        var countForCounts = [Int: Int]()
        var countForYear = [Int: Int]()
        for year in years {
            let count = eventsForYear[year]?.count ?? 0
            if !count.isZero {
                countForYear[year] = count
                print("\(count) schools starting in year: \(year).")
            }
            if let current = countForCounts[count] {
                countForCounts[count] = current + 1
            } else {
                countForCounts[count] = 1
            }
        }

        for (size, count) in countForCounts.sorted(by: { $0.0 < $1.0 }) {
            print("There are \(count) years with size \(size).")
        }

        for (size, count) in countForCounts.sorted(by: { $0.0 < $1.0 }) {
            let percent = Double(count) / Double(yearCount)
            print("Years with size: \(size) make up \(percent) of all the years.")
        }

        print("\(countForYear.keys.count) years out of \(yearCount) have at least one school start.")

        let sortedYears = countForYear.keys.sorted()
        for (index, year) in sortedYears.enumerated() {
            let nextIndex = index + 1
            if nextIndex != sortedYears.count {
                let nextYear = sortedYears[nextIndex]
                let distanceToNextYear = nextYear - year
                print("\(year) has a \(distanceToNextYear) year gap until next school occurance.")
            } else {
                print("\(year) is the last year.")
            }
        }

        print("\(sortedYears.first!) is the first year")

        for year in years {
            var eventsInYear = 0
            for event in events {
                if event.dates.startDate.year <= year && event.dates.endDate.year >= year {
                    eventsInYear += 1
                }
            }
            print("\(eventsInYear) concurrently open in \(year)")
        }

        var totalTimeOpen = 0
        for event in events {
            totalTimeOpen += event.dates.endDate.year - event.dates.startDate.year + 1
        }
        print("Average time open is: \(totalTimeOpen / events.count)")
    }
}
