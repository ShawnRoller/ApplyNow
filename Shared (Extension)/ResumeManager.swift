import Foundation
import os.log

/**
 * Manages the storage and retrieval of resume PDF files in UserDefaults.
 */
final class ResumeManager {
    /// UserDefaults key for storing the resume data
    private static let resumeKey = "com.riff-tech.EasyApply.resumeData"
    
    /// UserDefaults key for storing the resume filename
    private static let resumeFilenameKey = "com.riff-tech.EasyApply.resumeFilename"
    
    /// Test key for verifying UserDefaults access
    private static let testKey = "com.riff-tech.EasyApply.test"
    
    /// Shared instance for singleton access
    static let shared = ResumeManager()
    
    /// UserDefaults instance for data persistence
    private let defaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.riff-tech.EasyApply") {
            self.defaults = sharedDefaults
            os_log(.debug, "Successfully initialized shared UserDefaults with suite name")
            
            // Test if we can write to UserDefaults
            let testValue = "test_\(Date().timeIntervalSince1970)"
            defaults.set(testValue, forKey: ResumeManager.testKey)
            
            if let readValue = defaults.string(forKey: ResumeManager.testKey),
               readValue == testValue {
                os_log(.debug, "Successfully verified UserDefaults write/read access")
            } else {
                os_log(.error, "Failed to verify UserDefaults write/read access")
            }
        } else {
            os_log(.error, "Failed to initialize shared UserDefaults, falling back to standard")
            self.defaults = UserDefaults.standard
        }
    }
    
    /**
     * Retrieves the stored resume PDF data.
     * - Returns: Tuple containing the PDF data and filename, if available
     */
    func getResume() -> (data: Data, filename: String)? {
        os_log(.debug, "Attempting to retrieve resume")
        
        guard let filename = defaults.string(forKey: ResumeManager.resumeFilenameKey) else {
            os_log(.debug, "No resume filename found")
            return nil
        }
        
        let chunks = defaults.integer(forKey: "\(ResumeManager.resumeKey)_chunks")
        
        if chunks > 0 {
            os_log(.debug, "Retrieving resume from %d chunks", chunks)
            var completeData = Data()
            
            for i in 0..<chunks {
                let chunkKey = "\(ResumeManager.resumeKey)_chunk_\(i)"
                guard let chunkData = defaults.data(forKey: chunkKey) else {
                    os_log(.error, "Failed to retrieve chunk %d", i)
                    return nil
                }
                completeData.append(chunkData)
            }
            
            os_log(.debug, "Successfully retrieved resume: %{public}@", filename)
            os_log(.debug, "Total data size: %d bytes", completeData.count)
            return (completeData, filename)
        } else {
            guard let data = defaults.data(forKey: ResumeManager.resumeKey) else {
                os_log(.debug, "No resume data found")
                return nil
            }
            
            os_log(.debug, "Successfully retrieved resume: %{public}@", filename)
            os_log(.debug, "Data size: %d bytes", data.count)
            return (data, filename)
        }
    }
} 
