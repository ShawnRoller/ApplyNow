import Foundation
import os.log

/**
 * Manages storage of resume and other persistent data
 */
class StoreManager {
    static let shared = StoreManager()
    
    /// UserDefaults instance for data persistence
    private let userDefaults: UserDefaults
    private let resumeKey = "stored_resume"
    private let filenameKey = "resume_filename"
    
    private init() {
        // Use shared UserDefaults container for app group
        if let sharedDefaults = UserDefaults(suiteName: "group.com.riff-tech.EasyApply") {
            self.userDefaults = sharedDefaults
            os_log(.debug, "Successfully initialized shared UserDefaults with suite name")
        } else {
            os_log(.error, "Failed to initialize shared UserDefaults, falling back to standard")
            self.userDefaults = UserDefaults.standard
        }
    }
    
    /**
     * Resume data structure
     */
    struct Resume {
        let content: String
        let filename: String
    }
    
    /**
     * Saves a resume to persistent storage
     * @param content The content of the resume
     * @param filename The name of the resume file
     * @returns Boolean indicating success
     */
    @discardableResult
    func saveResume(content: String, filename: String) -> Bool {
        os_log(.debug, "Attempting to save resume: %{public}@", filename)
        os_log(.debug, "Content length: %{public}d", content.count)
        
        userDefaults.set(content, forKey: resumeKey)
        userDefaults.set(filename, forKey: filenameKey)
        let success = userDefaults.synchronize()
        
        // Verify the save
        if let savedContent = userDefaults.string(forKey: resumeKey),
           let savedFilename = userDefaults.string(forKey: filenameKey),
           savedContent == content,
           savedFilename == filename {
            os_log(.debug, "Successfully verified resume save")
            return true
        } else {
            os_log(.error, "Failed to verify resume save")
            
            // Debug info
            let hasContent = userDefaults.string(forKey: resumeKey) != nil
            let hasFilename = userDefaults.string(forKey: filenameKey) != nil
            os_log(.error, "Content exists: %{public}@, Filename exists: %{public}@", String(hasContent), String(hasFilename))
            
            return false
        }
    }
    
    /**
     * Retrieves the stored resume
     * @returns Optional Resume object
     */
    func getResume() -> Resume? {
        os_log(.debug, "Attempting to retrieve resume")
        
        guard let content = userDefaults.string(forKey: resumeKey),
              let filename = userDefaults.string(forKey: filenameKey) else {
            os_log(.debug, "No resume found in UserDefaults")
            os_log(.debug, "Keys present: %{public}@", userDefaults.dictionaryRepresentation().keys.joined(separator: ", "))
            return nil
        }
        
        os_log(.debug, "Found resume: %{public}@", filename)
        os_log(.debug, "Content length: %{public}d", content.count)
        return Resume(content: content, filename: filename)
    }
    
    /**
     * Removes the stored resume
     * @returns Boolean indicating success
     */
    @discardableResult
    func removeResume() -> Bool {
        os_log(.debug, "Attempting to remove resume")
        
        userDefaults.removeObject(forKey: resumeKey)
        userDefaults.removeObject(forKey: filenameKey)
        let success = userDefaults.synchronize()
        
        // Verify removal
        let verificationPassed = userDefaults.string(forKey: resumeKey) == nil &&
                               userDefaults.string(forKey: filenameKey) == nil
        
        if verificationPassed {
            os_log(.debug, "Successfully removed resume")
        } else {
            os_log(.error, "Failed to verify resume removal")
        }
        
        return verificationPassed
    }
}
