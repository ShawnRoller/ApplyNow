//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by riff-tech on 3/2/25.
//

import SafariServices
import os.log
import Foundation

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let openAIService = OpenAIService()
    private let storeManager = StoreManager.shared

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.debug, "Received message from browser.runtime.sendNativeMessage: %{public}@", String(describing: message))

        // Handle the message
        Task {
            let response = NSExtensionItem()
            var responseMessage: [String: Any] = [:]
            
            if let messageDict = message as? [String: Any],
               let command = messageDict["command"] as? String {
                os_log(.debug, "Processing command: %{public}@", command)
                
                switch command {
                case "get-resume":
                    os_log(.debug, "Attempting to get resume...")
                    if let resume = storeManager.getResume() {
                        os_log(.debug, "Found resume: %{public}@", resume.filename)
                        responseMessage = [
                            "filename": resume.filename,
                            "content": resume.content
                        ]
                        os_log(.debug, "Response prepared with content")
                    } else {
                        os_log(.error, "No resume found in StoreManager")
                        responseMessage = [
                            "error": "No resume found",
                            "filename": NSNull()
                        ]
                    }
                    
                case "generate-cover-letter":
                    os_log(.debug, "Attempting to generate cover letter...")
                    if let data = messageDict["data"] as? [String: Any],
                       let resume = data["resume"] as? String,
                       let jobDescription = data["jobDescription"] as? String,
                       let systemPrompt = data["systemPrompt"] as? String {
                        
                        let result = await openAIService.generateCoverLetter(
                            resume: resume,
                            jobDescription: jobDescription,
                            systemPrompt: systemPrompt
                        )
                        
                        switch result {
                        case .success(let coverLetter):
                            responseMessage = ["coverLetter": coverLetter]
                            os_log(.debug, "Cover letter generated successfully")
                        case .failure(let error):
                            responseMessage = ["error": error.localizedDescription]
                            os_log(.error, "Failed to generate cover letter: %{public}@", error.localizedDescription)
                        }
                    } else {
                        os_log(.error, "Invalid parameters for cover letter generation")
                        responseMessage = ["error": "Invalid parameters for cover letter generation"]
                    }
                    
                default:
                    os_log(.error, "Unknown command: %{public}@", command)
                    responseMessage = ["error": "Unknown command"]
                }
            } else {
                os_log(.error, "Invalid message format")
                responseMessage = ["error": "Invalid message format"]
            }
            
            os_log(.debug, "Sending response keys: %{public}@", responseMessage.keys.map { $0 }.joined(separator: ", "))
            
            if #available(iOS 15.0, macOS 11.0, *) {
                response.userInfo = [SFExtensionMessageKey: responseMessage]
            } else {
                response.userInfo = ["message": responseMessage]
            }
            
            context.completeRequest(returningItems: [response], completionHandler: nil)
        }
    }
}
