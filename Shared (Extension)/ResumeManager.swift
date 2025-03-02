import Foundation

/**
 * Manages the storage and retrieval of resume PDF files in UserDefaults.
 */
final class ResumeManager {
    /// UserDefaults key for storing the resume data
    private static let resumeKey = "com.riff-tech.EasyApply.resumeData"
    
    /// UserDefaults key for storing the resume filename
    private static let resumeFilenameKey = "com.riff-tech.EasyApply.resumeFilename"
    
    /// Shared instance for singleton access
    static let shared = ResumeManager()
    
    /// UserDefaults instance for data persistence
    private let defaults = UserDefaults(suiteName: "group.com.riff-tech.EasyApply")!
    
    private init() {}
    
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
} 
