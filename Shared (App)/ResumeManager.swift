import Foundation

/**
 * Manages the storage and retrieval of resume PDF files in UserDefaults.
 */
final class ResumeManager {
    /// UserDefaults key for storing the resume data
    private static let resumeKey = "com.riff-tech.ApplyNow.resumeData"
    
    /// UserDefaults key for storing the resume filename
    private static let resumeFilenameKey = "com.riff-tech.ApplyNow.resumeFilename"
    
    /// Shared instance for singleton access
    static let shared = ResumeManager()
    
    /// UserDefaults instance for data persistence
    private let defaults = UserDefaults(suiteName: "group.com.riff-tech.ApplyNow")!
    
    private init() {}
    
    /**
     * Saves the PDF data and filename to UserDefaults.
     * - Parameters:
     *   - data: The PDF file data to save
     *   - filename: The name of the PDF file
     * - Returns: Boolean indicating whether the save was successful
     */
    func saveResume(data: Data, filename: String) -> Bool {
        defaults.set(data, forKey: ResumeManager.resumeKey)
        defaults.set(filename, forKey: ResumeManager.resumeFilenameKey)
        return defaults.synchronize()
    }
    
    /**
     * Retrieves the stored resume PDF data.
     * - Returns: Tuple containing the PDF data and filename, if available
     */
    func getResume() -> (data: Data, filename: String)? {
        guard let data = defaults.data(forKey: ResumeManager.resumeKey),
              let filename = defaults.string(forKey: ResumeManager.resumeFilenameKey)
        else {
            return nil
        }
        return (data, filename)
    }
    
    /**
     * Removes the stored resume data from UserDefaults.
     * - Returns: Boolean indicating whether the removal was successful
     */
    func removeResume() -> Bool {
        defaults.removeObject(forKey: ResumeManager.resumeKey)
        defaults.removeObject(forKey: ResumeManager.resumeFilenameKey)
        return defaults.synchronize()
    }
} 
