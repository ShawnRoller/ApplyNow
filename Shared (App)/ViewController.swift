//
//  ViewController.swift
//  Shared (App)
//
//  Created by riff-tech on 3/2/25.
//

import WebKit

#if os(iOS)
import UIKit
import UniformTypeIdentifiers
typealias PlatformViewController = UIViewController
#elseif os(macOS)
import Cocoa
import SafariServices
import UniformTypeIdentifiers
typealias PlatformViewController = NSViewController
#endif

// Import ResumeManager from the same module
import Foundation

let extensionBundleIdentifier = "com.riff-tech.ApplyNow.Extension"

class ViewController: PlatformViewController, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet var webView: WKWebView!

    #if os(iOS)
    private lazy var documentPicker: UIDocumentPickerViewController = {
        let types: [UTType] = [.pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        return picker
    }()
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self

#if os(iOS)
        self.webView.scrollView.isScrollEnabled = false
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
        if let resume = ResumeManager.shared.getResume() {
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
            if ResumeManager.shared.removeResume() {
                updateResumeUI(withFilename: nil)
            }
            
        default:
            break
        }
    }

    private func selectResume() {
        #if os(iOS)
        present(documentPicker, animated: true)
        #elseif os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.beginSheetModal(for: view.window!) { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = panel.url,
                  let data = try? Data(contentsOf: url) else {
                return
            }
            
            if ResumeManager.shared.saveResume(data: data, filename: url.lastPathComponent) {
                self.updateResumeUI(withFilename: url.lastPathComponent)
            }
        }
        #endif
    }

    private func updateResumeUI(withFilename filename: String?) {
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
            let data = try Data(contentsOf: url)
            if ResumeManager.shared.saveResume(data: data, filename: url.lastPathComponent) {
                updateResumeUI(withFilename: url.lastPathComponent)
            }
        } catch {
            print("Error reading data from URL: \(error.localizedDescription)")
        }
        
        // Stop accessing security-scoped resource
        if didStartAccessing {
            url.stopAccessingSecurityScopedResource()
        }
        
        dismiss(animated: true)
    }
}
#endif
