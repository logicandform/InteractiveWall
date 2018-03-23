//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

protocol MediaControllerDelegate: class {
    func closeWindow(for mediaController: MediaViewController)
}

class MediaViewController: NSViewController {
    var gestureManager: GestureManager!
    weak var delegate: MediaControllerDelegate?
    var media: Media!

    func close() {
        delegate?.closeWindow(for: self)
        WindowManager.instance.closeWindow(for: self)
    }
}
