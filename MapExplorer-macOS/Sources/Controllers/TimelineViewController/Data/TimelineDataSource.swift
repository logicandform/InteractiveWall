//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


final class TimelineDataSource: NSObject, NSCollectionViewDataSource {

    var selectedIndexes = Set<Int>()
    var highlightedIndexes = Set<Int>()
    private(set) var events = [TimelineEvent]()
    private(set) var eventsForYear = [Int: [TimelineEvent]]()
    private(set) var eventsForMonth = [Int: [Month: [TimelineEvent]]]()
    private(set) var firstYear = Constants.firstYear
    private(set) var lastYear = (Calendar.current.component(.year, from: Date()) / 10) * 10 + 10
    private(set) var years: [Int]
    private let type = TimelineType.decade

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

    func setup(with records: [Record]) {
        let sortedRecords = records.sorted(by: { $0.type.timelineSortOrder < $1.type.timelineSortOrder })

        events = sortedRecords.compactMap { record in
            if let dates = record.dates {
                return TimelineEvent(id: record.id, type: record.type, title: record.title, dates: dates)
            } else {
                return nil
            }
        }

        // Add to year dictionary
        for event in events {
            if eventsForYear[event.dates.startDate.year] != nil {
                eventsForYear[event.dates.startDate.year]!.append(event)
            } else {
                eventsForYear[event.dates.startDate.year] = [event]
            }
        }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventsWithOverflow.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let timelineFlag = collectionView.makeItem(withIdentifier: TimelineFlagView.identifier, for: indexPath) as? TimelineFlagView else {
            return NSCollectionViewItem()
        }

        let event = eventsWithOverflow[indexPath.item]
        timelineFlag.event = event
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
                let layers = layout.layersForYear[year] ?? []
                tailView.set(layers)
                return tailView
            }
        default:
            return NSView()
        }

        return NSView()
    }
}
