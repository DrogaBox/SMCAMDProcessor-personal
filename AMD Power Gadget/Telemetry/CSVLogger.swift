//
//  CSVLogger.swift
//  AMD Power Gadget
//

import Foundation

// MARK: - CSV Logger Helper Class (Thread-safe & nonisolated to bypass actor deinit constraints)
class CSVLogger {
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "wtf.spinach.CSVLogger", qos: .background)
    
    func start(path: String, delimiter: String, headers: [String]) {
        queue.async {
            guard !path.isEmpty else { return }
            let fileURL = URL(fileURLWithPath: path)
            
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                let header = headers.joined(separator: delimiter) + "\n"
                try? header.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            self.fileHandle?.closeFile()
            self.fileHandle = try? FileHandle(forWritingTo: fileURL)
            self.fileHandle?.seekToEndOfFile()
        }
    }
    
    func stop() {
        queue.async {
            self.fileHandle?.closeFile()
            self.fileHandle = nil
        }
    }
    
    func write(line: String) {
        queue.async {
            if let data = line.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
        }
    }
    
    deinit {
        let handle = fileHandle
        queue.sync {
            handle?.closeFile()
        }
    }
}

