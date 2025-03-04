import AWSCore
import AWSCognitoIdentityProvider
import Foundation

/**
 * Service class for handling AWS Cognito authentication
 */
class AWSAuthService {
    /// Singleton instance
    static let shared = AWSAuthService()
    
    /// AWS Cognito configuration
    private struct CognitoConfig {
        static let poolId = "YOUR_USER_POOL_ID"
        static let clientId = "YOUR_CLIENT_ID"
        static let region = "YOUR_REGION" // e.g., "us-east-1"
    }
    
    private var userPool: AWSCognitoIdentityUserPool?
    private var currentUser: AWSCognitoIdentityUser?
    private var currentSession: AWSCognitoIdentityUserSession?
    
    /// The current authentication token, if available
    var currentToken: String? {
        return currentSession?.idToken?.tokenString
    }
    
    private init() {
        setupCognito()
    }
    
    /**
     * Sets up AWS Cognito configuration
     */
    private func setupCognito() {
        let serviceConfiguration = AWSServiceConfiguration(
            region: AWSRegionType(rawValue: CognitoConfig.region)!,
            credentialsProvider: nil
        )
        
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
            clientId: CognitoConfig.clientId,
            clientSecret: nil,
            poolId: CognitoConfig.poolId
        )
        
        AWSCognitoIdentityUserPool.register(
            with: serviceConfiguration,
            userPoolConfiguration: poolConfiguration,
            forKey: "UserPool"
        )
        
        userPool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }
    
    /**
     * Signs in a user with their username and password
     * @param username The user's username
     * @param password The user's password
     * @returns A Result containing the authentication token or an error
     */
    func signIn(username: String, password: String) async -> Result<String, Error> {
        return await withCheckedContinuation { continuation in
            guard let user = userPool?.getUser(username) else {
                continuation.resume(returning: .failure(AuthError.invalidUser))
                return
            }
            
            currentUser = user
            
            user.getSession(username, password: password, validationData: nil).continueWith { [weak self] task in
                if let error = task.error {
                    continuation.resume(returning: .failure(error))
                    return nil
                }
                
                guard let session = task.result,
                      let idToken = session.idToken?.tokenString else {
                    continuation.resume(returning: .failure(AuthError.noToken))
                    return nil
                }
                
                self?.currentSession = session
                continuation.resume(returning: .success(idToken))
                return nil
            }
        }
    }
    
    /**
     * Signs out the current user
     */
    func signOut() {
        currentUser?.signOut()
        currentUser = nil
        currentSession = nil
    }
    
    /**
     * Checks if a user is currently signed in
     * @returns True if a user is signed in, false otherwise
     */
    var isSignedIn: Bool {
        return currentUser != nil && currentSession != nil
    }
}

/**
 * Custom authentication errors
 */
enum AuthError: LocalizedError {
    case invalidUser
    case noToken
    
    var errorDescription: String? {
        switch self {
        case .invalidUser:
            return "Invalid user"
        case .noToken:
            return "No authentication token available"
        }
    }
} 