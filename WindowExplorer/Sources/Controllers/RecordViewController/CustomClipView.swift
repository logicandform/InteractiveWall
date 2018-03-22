//
//  CustomClipView.swift
//  WindowExplorer
//
//  Created by Jeremy Voldeng on 2018-03-22.
//  Copyright © 2018 JABT. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class CustomClipView: NSClipView {

    override var isFlipped: Bool {
        return true
    }
}
