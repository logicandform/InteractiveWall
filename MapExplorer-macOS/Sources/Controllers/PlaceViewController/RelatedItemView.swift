//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class RelatedItemView: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemView")
    static let nibName = NSNib.Name(rawValue: "RelatedItemView")

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
    @IBOutlet weak var imageView: NSImageView!

    var didTapItem: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        layer?.cornerRadius = 5.0
        layer?.masksToBounds = true
    }

    @IBAction func didTapView(_ sender: Any) {
        didTapItem?()
        layer?.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        }
    }
}
