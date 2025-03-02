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
