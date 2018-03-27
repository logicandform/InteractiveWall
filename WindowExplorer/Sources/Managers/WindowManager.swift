//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MONode
import PromiseKit

final class WindowManager {

    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()
    private var controllersForRecordInfo = [RecordInfo: NSViewController]()

    private struct Keys {
        static let map = "map"
        static let id = "id"
        static let position = "position"
    }


    // MARK: Init

    /// Use singleton instance
    private init() { }


    // MARK: API
 
    /// Must be done after application launches.
    func registerForNotifications() {
        for notification in WindowNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    func closeWindow(for controller: NSViewController) {
        if let responder = controller as? GestureResponder, let (window, _) = windows.first(where: { $0.value === responder.gestureManager }) {
            windows.removeValue(forKey: window)
            window.close()

            if controller is RecordViewController {
                for (recordInfo, dictionaryController) in controllersForRecordInfo {
                    if dictionaryController == controller {
                        controllersForRecordInfo.removeValue(forKey: recordInfo)
                    }
                }
            }
        }
    }

    @discardableResult
    func display(_ type: WindowType, at origin: CGPoint) -> NSViewController? {
        let window = WindowFactory.window(for: type, at: origin)

        if let controller = window.contentViewController {
            if let responder = controller as? GestureResponder {
                windows[window] = responder.gestureManager
            }

            return controller
        }

        return nil
    }

    // If the none of the screens contain the detail view, dealocate it
    func checkBounds(of controller: NSViewController) {

        guard let screenIndex = controller.view.window?.screen?.index else {
            dismissWindow(for: controller)
            return
        }

        var indicies = NSScreen.screens.indices

        if !Configuration.loadMapsOnFirstScreen {
            indicies.removeFirst()
        }

        if !indicies.contains(screenIndex) {
            dismissWindow(for: controller)
        }
    }

    private func dismissWindow(for controller: NSViewController) {
        if let mediaController = controller as? MediaViewController {
            mediaController.close()
        } else{
            closeWindow(for: controller)
        }
    }


    // MARK: Receiving Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let windowNotification = WindowNotification.with(notification.name), let info = notification.userInfo, let map = info[Keys.map] as? Int, let id = info[Keys.id] as? Int, let locationJSON = info[Keys.position] as? JSON, let location = CGPoint(json: locationJSON) else {
            return  
        }

        RecordFactory.record(for: windowNotification.type, id: id) { [weak self] record in
            if let record = record {
                let windowType = WindowType.record(record)
                let origin = location - CGPoint(x: windowType.size.width / 2, y: windowType.size.height)

                self?.handleDisplayingRecord(for: record, with: id, on: map, at: origin)
            }
        }
    }

    private func handleDisplayingRecord(for record: RecordDisplayable, with recordId: Int, on mapId: Int, at origin: CGPoint) {

        let recordInfo = RecordInfo(recordId: recordId, mapId: mapId, type: record.type)

        if let controller = controllersForRecordInfo[recordInfo] {
            animate(controller, to: origin)
            return
        }

        if let controller = display(.record(record), at: origin) {
            controllersForRecordInfo[recordInfo] = controller
        }
    }

    private func animate(_ controller: NSViewController, to origin: NSPoint) {
        let window = controller.view.window!
        var frame = window.frame
        frame.origin = origin

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 0.75
            NSAnimationContext.current.allowsImplicitAnimation = true
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            window.animator().setFrame(frame, display: true, animate: true)
        })
    }
}
