//  Copyright © 2018 JABT. All rights reserved.

import Foundation


private enum TimerState {
    case suspended
    case resumed
}


/// A simple API for using a `DispatchSourceTimer`. Runs on the main queue
class DispatchTimer {

    private var timer: DispatchSourceTimer!
    private var state = TimerState.suspended

    private struct Constants {
        static let defaultLeeway = DispatchTimeInterval.nanoseconds(10)
    }


    // MARK: Init

    /// Initialze a repeating timer with an interval, handler and queue
    init(interval: DispatchTimeInterval, handler: @escaping () -> Void, queue: DispatchQueue = .main) {
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer.schedule(deadline: .now(), repeating: interval, leeway: Constants.defaultLeeway)
        self.timer.setEventHandler {
            handler()
        }
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        resume()
    }


    // MARK: API

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
