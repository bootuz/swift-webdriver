import Foundation
import WebDriver


/// Errors specific to Chromium sessions
public enum ChromiumSessionError: Error, CustomStringConvertible {
    case invalidScreenshotData
    case cdpCommandNotImplemented
    case incognitoModeMustBeSetAtLaunch
    
    public var description: String {
        switch self {
        case .invalidScreenshotData:
            return "Invalid screenshot data received from Chromium"
        case .cdpCommandNotImplemented:
            return "Chrome DevTools Protocol command execution not fully implemented"
        case .incognitoModeMustBeSetAtLaunch:
            return "Incognito mode must be set at browser launch via capabilities"
        }
    }
} 
