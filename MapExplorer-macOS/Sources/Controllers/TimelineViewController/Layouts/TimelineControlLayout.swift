//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineControlLayout: NSCollectionViewFlowLayout {

    private var items = 0
    private var attributesForIndex = [Int: NSCollectionViewLayoutAttributes]()
    private var attributesForBorder: NSCollectionViewLayoutAttributes!

    private struct Constants {
        static let itemWidth: CGFloat = 70
        static let visibleItems = 7
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.sectionInset = NSEdgeInsetsZero
        self.itemSize = .zero
    }

    override init() {
        super.init()
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.sectionInset = NSEdgeInsetsZero
        self.itemSize = .zero
    }


    // MARK: Overrides

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView, let source = collectionView.dataSource else {
            return
        }

        items = source.collectionView(collectionView, numberOfItemsInSection: 0)
        for item in (0 ..< items) {
            attributesForIndex[item] = attributes(item: item)
        }
        attributesForBorder = borderAttributes()
    }

    override var collectionViewContentSize: NSSize {
        let totalWidth = CGFloat(items) * Constants.itemWidth
        let height = collectionView?.frame.height ?? 0
        return CGSize(width: totalWidth, height: height)
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        var layoutAttributes = [NSCollectionViewLayoutAttributes]()

        let minItem = max(0, Int(rect.minX / Constants.itemWidth))
        let maxItem = min(items, Int(rect.maxX / Constants.itemWidth))

        for item in (minItem...maxItem) {
            if let attributesForItem = attributesForIndex[item] {
                layoutAttributes.append(attributesForItem)
            }

            if item == items {
                layoutAttributes.append(attributesForBorder)
            }
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        return attributesForIndex[indexPath.item]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard elementKind == TimelineBorderView.supplementaryKind else {
            return nil
        }
        return attributesForBorder
    }


    // MARK: Helpers

    private func attributes(item: Int) -> NSCollectionViewLayoutAttributes {
        let indexPath = IndexPath(item: item, section: 0)
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        let x = CGFloat(item) * Constants.itemWidth
        let height = collectionView?.frame.height ?? 0
        attributes.frame = CGRect(origin: CGPoint(x: x, y: 0), size: CGSize(width: Constants.itemWidth, height: height))
        return attributes
    }

    private func borderAttributes() -> NSCollectionViewLayoutAttributes {
        let attributes = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: TimelineBorderView.supplementaryKind, with: .zero)
        let x = CGFloat(items - Constants.visibleItems) * Constants.itemWidth
        let collectionViewHeight = collectionView?.frame.height ?? 0
        let height = collectionViewHeight * 3/5
        let y = collectionViewHeight * 1/5
        attributes.frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: style.timelineBorderWidth, height: height))
        attributes.zIndex = 10
        return attributes
    }
}
