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
     * Saves the PDF data and filename to UserDefaults.
     * - Parameters:
     *   - data: The PDF file data to save
     *   - filename: The name of the PDF file
     * - Returns: Boolean indicating whether the save was successful
     */
    func saveResume(data: Data, filename: String) -> Bool {
        os_log(.debug, "Attempting to save resume: %{public}@", filename)
        os_log(.debug, "Data size: %d bytes", data.count)
        
        // Try saving in chunks if the data is large
        let chunkSize = 512 * 1024 // 512KB chunks
        if data.count > chunkSize {
            os_log(.debug, "Large file detected, saving in chunks")
            let chunks = data.count / chunkSize + (data.count % chunkSize > 0 ? 1 : 0)
            
            for i in 0..<chunks {
                let start = i * chunkSize
                let end = min(start + chunkSize, data.count)
                let chunk = data[start..<end]
                let chunkKey = "\(ResumeManager.resumeKey)_chunk_\(i)"
                defaults.set(chunk, forKey: chunkKey)
            }
            
            // Save chunk count and filename
            defaults.set(chunks, forKey: "\(ResumeManager.resumeKey)_chunks")
            defaults.set(filename, forKey: ResumeManager.resumeFilenameKey)
            
            // Verify the save
            if verifyChunkedSave(expectedChunks: chunks, filename: filename) {
                os_log(.debug, "Successfully saved and verified resume in %d chunks", chunks)
                return true
            } else {
                os_log(.error, "Failed to verify chunked save")
                return false
            }
        } else {
            // Save as single piece for smaller files
            defaults.set(data, forKey: ResumeManager.resumeKey)
            defaults.set(filename, forKey: ResumeManager.resumeFilenameKey)
            defaults.set(0, forKey: "\(ResumeManager.resumeKey)_chunks")
            
            // Verify the save
            if let savedData = defaults.data(forKey: ResumeManager.resumeKey),
               let savedFilename = defaults.string(forKey: ResumeManager.resumeFilenameKey),
               savedData.count == data.count,
               savedFilename == filename {
                os_log(.debug, "Successfully saved and verified resume")
                os_log(.debug, "Verification - Found saved data: %d bytes", savedData.count)
                os_log(.debug, "Verification - Found saved filename: %{public}@", savedFilename)
                return true
            } else {
                os_log(.error, "Failed to verify save")
                return false
            }
        }
    }
    
    /**
     * Retrieves the stored resume PDF data.
     * - Returns: Tuple containing the PDF data and filename, if available
     */
    func getResume() -> (data: Data, filename: String)? {
        os_log(.debug, "Attempting to retrieve resume")
        
        guard let filename = defaults.string(forKey: ResumeManager.resumeFilenameKey) else {
            os_log(.error, "Failed to retrieve resume filename")
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
                os_log(.error, "Failed to retrieve resume data")
                return nil
            }
            
            os_log(.debug, "Successfully retrieved resume: %{public}@", filename)
            os_log(.debug, "Data size: %d bytes", data.count)
            return (data, filename)
        }
    }
    
    /**
     * Removes the stored resume data from UserDefaults.
     * - Returns: Boolean indicating whether the removal was successful
     */
    func removeResume() -> Bool {
        os_log(.debug, "Attempting to remove resume")
        
        // Remove any chunked data
        let chunks = defaults.integer(forKey: "\(ResumeManager.resumeKey)_chunks")
        if chunks > 0 {
            for i in 0..<chunks {
                let chunkKey = "\(ResumeManager.resumeKey)_chunk_\(i)"
                defaults.removeObject(forKey: chunkKey)
            }
        }
        
        defaults.removeObject(forKey: ResumeManager.resumeKey)
        defaults.removeObject(forKey: ResumeManager.resumeFilenameKey)
        defaults.removeObject(forKey: "\(ResumeManager.resumeKey)_chunks")
        
        // Verify removal
        let verificationPassed = defaults.data(forKey: ResumeManager.resumeKey) == nil &&
            defaults.string(forKey: ResumeManager.resumeFilenameKey) == nil &&
            defaults.integer(forKey: "\(ResumeManager.resumeKey)_chunks") == 0
        
        if verificationPassed {
            os_log(.debug, "Successfully removed resume")
        } else {
            os_log(.error, "Failed to verify resume removal")
        }
        
        return verificationPassed
    }
    
    /**
     * Verifies that chunked data was saved correctly
     * - Parameters:
     *   - expectedChunks: The number of chunks that should be present
     *   - filename: The filename that should be saved
     * - Returns: Boolean indicating whether the verification passed
     */
    private func verifyChunkedSave(expectedChunks: Int, filename: String) -> Bool {
        guard let savedFilename = defaults.string(forKey: ResumeManager.resumeFilenameKey),
              savedFilename == filename,
              defaults.integer(forKey: "\(ResumeManager.resumeKey)_chunks") == expectedChunks else {
            return false
        }
        
        for i in 0..<expectedChunks {
            let chunkKey = "\(ResumeManager.resumeKey)_chunk_\(i)"
            guard defaults.data(forKey: chunkKey) != nil else {
                return false
            }
        }
        
        return true
    }
} 
