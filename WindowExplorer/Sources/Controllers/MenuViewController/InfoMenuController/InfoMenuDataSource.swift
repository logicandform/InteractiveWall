//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


final class InfoMenuDataSource: NSObject, NSCollectionViewDataSource {


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return NSCollectionViewItem()
    }
}
