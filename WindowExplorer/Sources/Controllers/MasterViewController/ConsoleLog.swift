//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum LogType {
    case success
    case status
    case warning
    case failed
    case error

    var title: String {
        switch self {
        case .success:
            return "Success"
        case .status:
            return "Status"
        case .warning:
            return "Warning"
        case .failed:
            return "Failed"
        case .error:
            return "Error"
        }
    }

    var color: NSColor {
        switch self {
        case .success:
            return .green
        case .status:
            return .cyan
        case .warning:
            return .yellow
        case .failed:
            return .orange
        case .error:
            return .red
        }
    }
}


struct ConsoleLog {

    let type: LogType
    let message: String
    let date = Date()


    // MARK: Init

    init(type: LogType, message: String) {
        self.type = type
        self.message = message
    }
}
