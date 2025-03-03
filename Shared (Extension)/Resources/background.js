// Log when background script is loaded
console.log("Background script loaded");

// Listen for runtime messages
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Background received message:", message);
  return false; // Don't use sendResponse
});

// Log any native messaging errors
browser.runtime.onMessageExternal.addListener((message, sender) => {
  console.log("Received external message:", message, "from:", sender);
});

// Handle native messaging errors
function handleNativeMessagingError(error) {
  console.error("Native messaging error:", error);
}

browser.runtime.onInstalled.addListener(() => {
  console.log("Extension installed/updated");
});

// Listen for messages from content scripts or popup
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    console.log("received request in background: ", message);
  if (message.type === "get-resume") {
    browser.runtime.sendNativeMessage("com.riff-tech.EasyApply.Extension", {
      command: "get-resume"
    }).then((nativeResponse) => {
      sendResponse(nativeResponse);
    }).catch((error) => {
      console.error("Native messaging error:", error);
      sendResponse({ error: error.message });
    });
    // Return true to indicate async response
    return true;
  }
});
