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
        let response = NSExtensionItem()
        var responseMessage: [String: Any] = [:]
        
        if let messageDict = message as? [String: Any],
           let command = messageDict["command"] as? String {
            os_log(.debug, "Processing command: %{public}@", command)
            
            switch command {
            case "get-resume":
                os_log(.debug, "Attempting to get resume...")
                if let resume = ResumeManager.shared.getResume() {
                    os_log(.debug, "Found resume: %{public}@", resume.filename)
                    responseMessage = [
                        "filename": resume.filename,
                        "content": resume.content
                    ]
                    os_log(.debug, "Response prepared with content")
                } else {
                    os_log(.error, "No resume found in ResumeManager")
                    responseMessage = [
                        "error": "No resume found",
                        "filename": NSNull()
                    ]
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
