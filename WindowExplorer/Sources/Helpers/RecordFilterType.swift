//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import AppKit

enum RecordFilterType {
    case image
    case school
    case artifact
    case event
    case organization
    case theme
    
    var title: String? {
        if let recordType = self.recordType {
            return recordType.title
        }
        
        switch self {
        case .image:
            return "IMAGES"
        default:
            return nil
        }
    }
    
    var color: NSColor {
        if let recordType = self.recordType {
            return recordType.color
        }
        
        switch self {
        case .image:
            return style.organizationColor
        default:
            return style.unselectedRecordIcon
        }
    }
    
    var placeholder: NSImage? {
        if let recordType = self.recordType {
            return recordType.placeholder
        }
        
        switch self {
        case .image:
            // NOTE: placeholder for now, need actual icon
            return NSImage(named: "school-icon")!
        default:
            return nil
        }
    }
    
    var recordType: RecordType? {
        switch self {
        case .image:
            return nil
        case .school:
            return .school
        case .event:
            return .event
        case .organization:
            return .organization
        case .artifact:
            return .artifact
        case .theme:
            return .theme
        }
    }
    
    static var allValues: [RecordFilterType] {
        return [.image, .school, .event, .organization, .artifact]
    }
}
