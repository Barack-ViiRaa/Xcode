//
//  ErrorLogger.swift
//  ViiRaa
//
//  Created by Claude Code on 2025-12-18.
//  Persistent error logging for debugging on physical devices
//  Bug #22 fix: Allows viewing Junction connection errors without Xcode console
//

import Foundation

class ErrorLogger {
    static let shared = ErrorLogger()

    private let logFileName = "viiraa_errors.log"
    private let maxLogSize = 100_000 // 100KB max log file size

    private var logFileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(logFileName)
    }

    private init() {}

    /// Log an error message with timestamp
    func log(_ message: String, category: String = "General") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(category)] \(message)\n"

        print(logEntry) // Also print to console

        guard let fileURL = logFileURL else { return }

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        // Append to log file
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            if let data = logEntry.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()

            // Check file size and trim if needed
            trimLogFileIfNeeded()
        } catch {
            print("Failed to write to log file: \(error.localizedDescription)")
        }
    }

    /// Get all log contents as a string
    func getLogContents() -> String {
        guard let fileURL = logFileURL else {
            return "Log file URL not available"
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return "No log file exists yet"
        }

        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            return "Failed to read log file: \(error.localizedDescription)"
        }
    }

    /// Clear all logs
    func clearLogs() {
        guard let fileURL = logFileURL else { return }

        do {
            try FileManager.default.removeItem(at: fileURL)
            log("Logs cleared", category: "System")
        } catch {
            print("Failed to clear logs: \(error.localizedDescription)")
        }
    }

    /// Trim log file if it exceeds max size
    private func trimLogFileIfNeeded() {
        guard let fileURL = logFileURL else { return }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            guard let fileSize = attributes[.size] as? Int, fileSize > maxLogSize else {
                return
            }

            // Keep only the last 50% of the log file
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.components(separatedBy: "\n")
            let keepLines = lines.suffix(lines.count / 2)
            let newContents = keepLines.joined(separator: "\n")

            try newContents.write(to: fileURL, atomically: true, encoding: .utf8)
            log("Log file trimmed (was \(fileSize) bytes)", category: "System")
        } catch {
            print("Failed to trim log file: \(error.localizedDescription)")
        }
    }

    /// Get log file path for sharing
    func getLogFilePath() -> String? {
        return logFileURL?.path
    }
}
