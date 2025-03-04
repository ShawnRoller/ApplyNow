//
//  ViewController.swift
//  Shared (App)
//
//  Created by riff-tech on 3/2/25.
//

import WebKit
import os

#if os(iOS)
import UIKit
import UniformTypeIdentifiers
typealias PlatformViewController = UIViewController
import Amplify
#elseif os(macOS)
import Cocoa
import SafariServices
import UniformTypeIdentifiers
typealias PlatformViewController = NSViewController
#endif

import Foundation

let extensionBundleIdentifier = "com.riff-tech.EasyApply.Extension"

class ViewController: PlatformViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let storeManager = StoreManager.shared
    private let openAIService = OpenAIService()
    
    @IBOutlet var webView: WKWebView!
    
#if os(iOS)
    private lazy var documentPicker: UIDocumentPickerViewController = {
        let types: [UTType] = [.text, .plainText]  // Only allow text files
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        return picker
    }()
    
    // Cognito auth
    let signInButton = UIButton(type: .system)
    let signOutButton = UIButton(type: .system)
#endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.navigationDelegate = self
        
#if os(iOS)
        self.webView.scrollView.isScrollEnabled = false
        
        setupUI()
        checkUserSession()
    
#endif
        
        self.webView.configuration.userContentController.add(self, name: "controller")
        
        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
#if os(iOS)
        webView.evaluateJavaScript("show('ios')")
#elseif os(macOS)
        webView.evaluateJavaScript("show('mac')")
        
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else {
                // Insert code to inform the user that something went wrong.
                return
            }
            
            DispatchQueue.main.async {
                if #available(macOS 13, *) {
                    webView.evaluateJavaScript("show('mac', \(state.isEnabled), true)")
                } else {
                    webView.evaluateJavaScript("show('mac', \(state.isEnabled), false)")
                }
            }
        }
#endif
        
        // Update UI with existing resume if available
        if let resume = storeManager.getResume() {
            updateResumeUI(withFilename: resume.filename)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let command = message.body as? String else { return }
        
        switch command {
        case "open-preferences":
#if os(macOS)
            SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
                guard error == nil else {
                    return
                }
                
                DispatchQueue.main.async {
                    NSApp.terminate(self)
                }
            }
#endif
            
        case "select-resume":
            selectResume()
            
        case "remove-resume":
            if storeManager.removeResume() {
                updateResumeUI(withFilename: nil)
            }
            
        default:
            print("Unknown command received:", command)
        }
    }
    
    private func selectResume() {
#if os(iOS)
        present(documentPicker, animated: true)
#elseif os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text, .plainText]  // Only allow text files
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = panel.url else {
                os_log(.debug, "Document picker cancelled or no URL")
                return
            }
            
            do {
                os_log(.debug, "Reading file: %{public}@", url.lastPathComponent)
                let content = try String(contentsOf: url, encoding: .utf8)
                os_log(.debug, "File content length: %{public}d", content.count)
                
                if self.storeManager.saveResume(content: content, filename: url.lastPathComponent) {
                    os_log(.debug, "Successfully saved resume")
                    self.updateResumeUI(withFilename: url.lastPathComponent)
                } else {
                    os_log(.error, "Failed to save resume")
                    // TODO: Show error to user
                }
            } catch {
                os_log(.error, "Error reading file: %{public}@", error.localizedDescription)
                // TODO: Show error to user
            }
        }
#endif
    }
    
    private func updateResumeUI(withFilename filename: String?) {
        os_log(.debug, "Updating UI with filename: %{public}@", filename ?? "nil")
        let script = "updateResumeStatus('\(filename ?? "")')"
        webView.evaluateJavaScript(script)
    }
}

#if os(iOS)
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("Error: no URL returned")
            return
        }
        
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            if storeManager.saveResume(content: content, filename: url.lastPathComponent) {
                updateResumeUI(withFilename: url.lastPathComponent)
            }
        } catch {
            print("Error reading text from file: \(error.localizedDescription)")
            // TODO: Show error to user
        }
        
        if didStartAccessing {
            url.stopAccessingSecurityScopedResource()
        }
        
        dismiss(animated: true)
    }
}
#endif


extension ViewController {
    private func setupUI() {
        view.backgroundColor = .white
        
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.isHidden = true
        
        view.addSubview(signInButton)
        view.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20)
        ])
    }
    
    private func checkUserSession() {
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                let isSignedIn = session.isSignedIn
                DispatchQueue.main.async {
                    self.signInButton.isHidden = isSignedIn
                    self.signOutButton.isHidden = !isSignedIn
                }
            } catch {
                print("Error fetching auth session: \(error)")
            }
        }
    }
    
    @objc private func signInTapped() {
        Task {
            do {
                let signInResult = try await Amplify.Auth.signIn(
                    username: "test@example.com",
                    password: "Test123!@#"
                )
                
//                let signInResult = try await Amplify.Auth.signInWithWebUI(presentationAnchor: view.window!)
                if signInResult.isSignedIn {
                    DispatchQueue.main.async {
                        self.signInButton.isHidden = true
                        self.signOutButton.isHidden = false
                    }
                }
            } catch {
                print("Sign in failed: \(error)")
                let signUpResult = try await Amplify.Auth.signUp(username: "test@xample.com", password: "Test123!@#")
                
                print (signUpResult)
                if signUpResult.isSignUpComplete {
                    DispatchQueue.main.async {
                        self.signInButton.isHidden = true
                        self.signOutButton.isHidden = false
                    }
                }
            }
        }
    }
    
    @objc private func signOutTapped() {
        Task {
            let _ = await Amplify.Auth.signOut()
            DispatchQueue.main.async {
                self.signInButton.isHidden = false
                self.signOutButton.isHidden = true
            }
        }
    }
}
