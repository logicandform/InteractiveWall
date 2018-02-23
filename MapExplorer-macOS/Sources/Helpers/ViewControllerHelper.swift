//
//  ViewControllerHelper.swift
//  MapExplorer-macOS
//
//  Created by Jeremy Voldeng on 2018-02-22.
//  Copyright © 2018 JABT. All rights reserved.
//

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


class ViewControllerHelper {


    /// Checks if the placeView currently displayed is hidden behind the screen, and adjusts it accordingly.
    static func adjustBoundaries(of view: NSView, in mainView: NSView) {
        let origin = view.frame.origin
        if origin.y < 0 {
            view.frame.origin = CGPoint(x: view.frame.origin.x, y: 15)
        }
        if origin.x < 0 {
            view.frame.origin = CGPoint(x: 15, y: view.frame.origin.y)
        }
        if view.frame.maxX > mainView.frame.maxX {
            view.frame.origin = CGPoint(x: mainView.frame.maxX - view.frame.width, y: view.frame.origin.y)
        }
    }
}
