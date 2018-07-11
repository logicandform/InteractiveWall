//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class TimelineDataSource: NSObject, NSCollectionViewDataSource {

    var selectedIndexes = Set<Int>()
    let firstYear = Constants.firstYear
    let lastYear = Constants.lastYear
    private(set) var events = [TimelineEvent]()
    private(set) var eventsForYear = [Int: [TimelineEvent]]()

    private struct Constants {
        static let firstYear = 1867
        static let lastYear = 1980
    }


    // MARK: Init

    override init() {
        super.init()
        setupEvents()
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
        }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return events.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let timelineItem = collectionView.makeItem(withIdentifier: TimelineItemView.identifier, for: indexPath) as? TimelineItemView, let attributes = collectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) else {
            return NSCollectionViewItem()
        }

        timelineItem.event = events[indexPath.item]
        if selectedIndexes.contains(indexPath.item) {
            timelineItem.animate(to: attributes.size)
        }
        return timelineItem
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        guard let headerView = collectionView.makeSupplementaryView(ofKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier, for: indexPath) as? TimelineHeaderView else {
            return NSView()
        }

        let year = firstYear + indexPath.item
        headerView.textLabel.stringValue = "\(year)"
        return headerView
    }
}
