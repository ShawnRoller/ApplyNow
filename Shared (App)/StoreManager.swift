import Foundation
import os.log

/**
 * Manages the storage and retrieval of resume text content in UserDefaults.
 */
final class StoreManager {
    /// UserDefaults key for storing the resume text content
    private static let resumeKey = "com.riff-tech.EasyApply.resumeText"
    
    /// UserDefaults key for storing the resume filename
    private static let resumeFilenameKey = "com.riff-tech.EasyApply.resumeFilename"
    
    /// Shared instance for singleton access
    static let shared = StoreManager()
    
    /// UserDefaults instance for data persistence
    private let defaults: UserDefaults
    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.riff-tech.EasyApply") {
            self.defaults = sharedDefaults
            os_log(.debug, "Successfully initialized shared UserDefaults with suite name")
        } else {
            os_log(.error, "Failed to initialize shared UserDefaults, falling back to standard")
            self.defaults = UserDefaults.standard
        }
    }
    
    /**
     * Saves the resume text content and filename to UserDefaults.
     * @param content The text content of the resume
     * @param filename The name of the resume file
     * @returns Boolean indicating whether the save was successful
     */
    func saveResume(content: String, filename: String) -> Bool {
        os_log(.debug, "Saving resume: %{public}@", filename)
        
        defaults.set(content, forKey: StoreManager.resumeKey)
        defaults.set(filename, forKey: StoreManager.resumeFilenameKey)
        
        // Verify the save
        if let savedContent = defaults.string(forKey: StoreManager.resumeKey),
           let savedFilename = defaults.string(forKey: StoreManager.resumeFilenameKey),
           savedContent == content,
           savedFilename == filename {
            os_log(.debug, "Successfully saved resume")
            return true
        } else {
            os_log(.error, "Failed to verify resume save")
            return false
        }
    }
    
    /**
     * Retrieves the stored resume text content.
     * @returns Tuple containing the text content and filename, if available
     */
    func getResume() -> (content: String, filename: String)? {
        os_log(.debug, "Attempting to retrieve resume")
        
        guard let filename = defaults.string(forKey: StoreManager.resumeFilenameKey),
              let content = defaults.string(forKey: StoreManager.resumeKey) else {
            os_log(.debug, "No resume found")
            return nil
        }
        
        os_log(.debug, "Successfully retrieved resume: %{public}@", filename)
        return (content, filename)
    }
    
    /**
     * Removes the stored resume from UserDefaults.
     * @returns Boolean indicating whether the removal was successful
     */
    func removeResume() -> Bool {
        os_log(.debug, "Attempting to remove resume")
        
        defaults.removeObject(forKey: StoreManager.resumeKey)
        defaults.removeObject(forKey: StoreManager.resumeFilenameKey)
        
        // Verify removal
        let verificationPassed = defaults.string(forKey: StoreManager.resumeKey) == nil &&
        defaults.string(forKey: StoreManager.resumeFilenameKey) == nil
        
        if verificationPassed {
            os_log(.debug, "Successfully removed resume")
        } else {
            os_log(.error, "Failed to verify resume removal")
        }
        
        return verificationPassed
    }
}
