//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by riff-tech on 3/2/25.
//

import SafariServices
import os.log

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

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        // Handle the message
        let response = NSExtensionItem()
        var responseMessage: [String: Any] = [:]
        
        if let messageDict = message as? [String: Any],
           let command = messageDict["command"] as? String {
            switch command {
            case "get-resume":
                if let resume = ResumeManager.shared.getResume() {
                    responseMessage = ["filename": resume.filename]
                }
            default:
                break
            }
        }
        
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [SFExtensionMessageKey: responseMessage]
        } else {
            response.userInfo = ["message": responseMessage]
        }
        
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
