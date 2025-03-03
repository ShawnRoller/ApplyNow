import Foundation

/**
 * Service class for handling OpenAI API requests
 */
class OpenAIService {
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"
    private let temperature = 0.7
    private let maxTokens = 1000
    
    private var apiKey: String {
        // TODO: Move to secure storage/keychain
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    /**
     * Generates a cover letter using OpenAI's API
     * @param resume The resume content
     * @param jobDescription The job description
     * @param systemPrompt The system prompt for the AI
     * @returns A tuple containing the generated cover letter or error
     */
    func generateCoverLetter(
        resume: String,
        jobDescription: String,
        systemPrompt: String
    ) async -> Result<String, Error> {
        guard let url = URL(string: apiURL) else {
            return .failure(OpenAIError.invalidURL)
        }
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Write a brief cover letter for the following job description:\n\n\(jobDescription)\n\nBased on this resume:\n\n\(resume)"]
        ]
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(OpenAIError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(OpenAIError.requestFailed(statusCode: httpResponse.statusCode))
            }
            
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = result.choices.first?.message.content else {
                return .failure(OpenAIError.noContent)
            }
            
            return .success(content)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Error Types
enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .noContent:
            return "No content in response"
        }
    }
}

// MARK: - Response Types
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 
