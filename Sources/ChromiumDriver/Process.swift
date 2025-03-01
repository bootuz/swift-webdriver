import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A cross-platform process wrapper that provides basic process management capabilities.
#if os(macOS)
// On macOS, we can use the built-in Process class
public typealias ChromiumProcess = Foundation.Process
#else
// On other platforms, we provide our own implementation
public class ChromiumProcess {
    public var executableURL: URL?
    public var arguments: [String]?
    public var standardOutput: Any?
    public var standardError: Any?
    private var isProcessRunning = false
    private var pid: Int32 = 0
    
    public init() {}
    
    public func run() throws {
        guard let executableURL = executableURL else {
            throw ProcessError.noExecutable
        }
        
        #if os(Linux)
        // Linux implementation using fork/exec
        let pid = fork()
        if pid < 0 {
            throw ProcessError.executionFailed("Failed to fork process")
        } else if pid == 0 {
            // Child process
            let args = [executableURL.path] + (arguments ?? [])
            let cArgs = args.map { strdup($0) } + [nil]
            execv(executableURL.path, cArgs)
            fatalError("Exec failed")
        } else {
            // Parent process
            self.pid = pid
            self.isProcessRunning = true
        }
        #elseif os(Windows)
        // Basic Windows implementation
        // This would normally use the Windows API, but we'll use a simple placeholder
        self.isProcessRunning = true
        print("Starting process on Windows (simulated): \(executableURL.path)")
        #else
        throw ProcessError.unsupportedPlatform
        #endif
    }
    
    public func terminate() {
        guard isProcessRunning else { return }
        
        #if os(Linux)
        kill(pid, SIGTERM)
        #elseif os(Windows)
        print("Terminating process on Windows (simulated)")
        #endif
        
        isProcessRunning = false
    }
    
    public var isRunning: Bool {
        guard isProcessRunning else { return false }
        
        #if os(Linux)
        var status: Int32 = 0
        let result = waitpid(pid, &status, WNOHANG)
        return result == 0
        #elseif os(Windows)
        // Simple simulation for Windows
        return isProcessRunning
        #else
        return false
        #endif
    }
}

public enum ProcessError: Error, CustomStringConvertible {
    case noExecutable
    case unsupportedPlatform
    case executionFailed(String)
    
    public var description: String {
        switch self {
        case .noExecutable:
            return "No executable URL specified"
        case .unsupportedPlatform:
            return "Process execution not supported on this platform"
        case .executionFailed(let reason):
            return "Failed to execute process: \(reason)"
        }
    }
}
#endif 
