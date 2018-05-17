//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class ImageZoomControl: NSView {

    static let nib = NSNib.Name(rawValue: "ImageZoomControl")

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var seekBar: NSSlider!


    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        Bundle.main.loadNibNamed(ImageZoomControl.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }


    
}
