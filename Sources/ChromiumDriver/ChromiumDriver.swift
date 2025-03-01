import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebDriver

/// Manages Chromium browser instances and provides WebDriver functionality for Chromium browsers.
public class ChromiumDriver: WebDriver {
    private let httpDriver: HTTPWebDriver
    private var process: ChromiumProcess?
    private let chromeDriverPath: String
    private let port: Int
    
    /// Creates a new ChromiumDriver instance
    /// - Parameters:
    ///   - chromeDriverPath: Path to the chromedriver executable
    ///   - port: Port to use for ChromeDriver
    ///   - startDriver: Automatically start the ChromeDriver process
    /// - Throws: Error if the driver cannot be started
    public init(chromeDriverPath: String, port: Int = 9515, startDriver: Bool = true) throws {
        self.chromeDriverPath = chromeDriverPath
        self.port = port
        self.httpDriver = HTTPWebDriver(endpoint: URL(string: "http://localhost:\(port)")!)
        
        if startDriver {
            try startChromeDriver()
        }
    }
    
    deinit {
        try? stopChromeDriver()
    }
    
    /// Static method to create and start a ChromiumDriver instance
    /// - Returns: A configured ChromiumDriver instance
    /// - Throws: Error if the driver cannot be started
    public static func start(path: String) throws -> ChromiumDriver {
        return try ChromiumDriver(chromeDriverPath: path)
    }
    
    /// Starts the ChromeDriver process
    /// - Throws: Error if the driver cannot be started
    public func startChromeDriver() throws {
        guard process == nil else { return }
        
        let process = ChromiumProcess()
        process.executableURL = URL(fileURLWithPath: chromeDriverPath)
        process.arguments = ["--port=\(port)"]
        
        #if os(macOS)
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        #endif
        
        try process.run()
        self.process = process
        
        // Wait for ChromeDriver to be ready
        try waitForDriverReady(timeout: 5)
    }
    
    /// Stops the ChromeDriver process
    /// - Throws: Error if the driver cannot be stopped
    public func stopChromeDriver() throws {
        guard let process = process, process.isRunning else { return }
        process.terminate()
        self.process = nil
    }
    
    /// Waits for ChromeDriver to be ready to accept connections
    /// - Parameter timeout: Maximum time to wait in seconds
    /// - Throws: Error if the driver is not ready within the timeout
    private func waitForDriverReady(timeout: TimeInterval) throws {
        let startTime = Date()
        var lastError: Error?
        
        while Date().timeIntervalSince(startTime) < timeout {
            do {
                _ = try httpDriver.status
                return
            } catch {
                lastError = error
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        throw ChromiumDriverError.driverNotReady(lastError)
    }
    
    // MARK: - WebDriver Protocol
    
    @discardableResult
    public func send<Req: Request>(_ request: Req) throws -> Req.Response {
        return try httpDriver.send(request)
    }
    
    public func isInconclusiveInteraction(error: ErrorResponse.Status) -> Bool {
        // For Chromium, certain errors might indicate temporary issues that can be retried
        switch error {
            case .staleElementReference, .elementNotVisible, .elementIsNotSelectable, .noSuchDriver:
            return true
        default:
            return false
        }
    }
}

/// Errors specific to ChromiumDriver
public enum ChromiumDriverError: Error, CustomStringConvertible {
    case driverNotReady(Error?)
    case browserNotFound
    case driverProcessFailed(Error)
    
    public var description: String {
        switch self {
        case .driverNotReady(let error):
            if let error = error {
                return "ChromeDriver failed to start: \(error)"
            } else {
                return "ChromeDriver failed to start within the timeout period"
            }
        case .browserNotFound:
            return "Could not find Chrome or Chromium browser"
        case .driverProcessFailed(let error):
            return "ChromeDriver process failed: \(error)"
        }
    }
} 
