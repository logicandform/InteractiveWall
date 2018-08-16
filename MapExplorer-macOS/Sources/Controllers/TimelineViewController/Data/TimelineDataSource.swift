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
        return events.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let timelineFlag = collectionView.makeItem(withIdentifier: TimelineFlagView.identifier, for: indexPath) as? TimelineFlagView else {
            return NSCollectionViewItem()
        }

        timelineFlag.event = events[indexPath.item]
        return timelineFlag
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        switch kind {
        case TimelineHeaderView.supplementaryKind:
            if let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineHeaderView.identifier, for: indexPath) as? TimelineHeaderView {
                let month = Month.allValues[indexPath.item % Month.allValues.count]
                let year = firstYear + (indexPath.item % years.count)
                let title = type == .month ? month.abbreviation : year.description
                headerView.textLabel.stringValue = title
                return headerView
            }
        case TimelineBorderView.supplementaryKind:
            if let borderView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineBorderView.identifier, for: indexPath) as? TimelineBorderView {
                return borderView
            }
        case TimelineTailView.supplementaryKind:
            if let tailView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineTailView.identifier, for: indexPath) as? TimelineTailView, let layout = collectionView.collectionViewLayout as? TimelineDecadeFlagLayout {
                let year = indexPath.item
                let tails = layout.tailsForYear[year] ?? []
                tailView.set(tails, year: year)
                return tailView
            }
        default:
            return NSView()
        }

        return NSView()
    }


    // MARK: Helpers

    private func setupEvents(for records: [Record]) {
        let sortedRecords = records.sorted(by: { $0.type.timelineSortOrder < $1.type.timelineSortOrder })

        for record in sortedRecords {
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
    }
}
