// Log when background script is loaded
console.log("Background script loaded");

/**
 * Handles native messaging errors
 * @param {Error} error - The error to handle
 */
function handleNativeMessagingError(error) {
  console.error("Native messaging error:", error);
}

// Listen for runtime messages
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Background received message:", message);
  console.log("Message type:", message.type);
  console.log("Message data:", message.data);

  switch (message.type) {
    case "get-resume":
      console.log("Processing get-resume request");
      browser.runtime
        .sendNativeMessage("com.riff-tech.EasyApply.Extension", {
          command: "get-resume",
        })
        .then((nativeResponse) => {
          console.log("Native response for get-resume:", nativeResponse);
          sendResponse(nativeResponse);
        })
        .catch((error) => {
          handleNativeMessagingError(error);
          sendResponse({ error: error.message });
        });
          
      return true;

    case "generate-cover-letter":
      console.log("Processing generate-cover-letter request");
      if (!message.data) {
        console.error("No data provided for cover letter generation");
        sendResponse({ error: "No data provided for cover letter generation" });
        return true;
      }

      console.log("Sending to native messaging:", {
        command: "generate-cover-letter",
        data: message.data,
      });

      browser.runtime
        .sendNativeMessage("com.riff-tech.EasyApply.Extension", {
          command: "generate-cover-letter",
          data: message.data,
        })
        .then((nativeResponse) => {
          console.log(
            "Native response for generate-cover-letter:",
            nativeResponse
          );
          sendResponse(nativeResponse);
        })
        .catch((error) => {
          handleNativeMessagingError(error);
          sendResponse({ error: error.message });
        });
      return true;

    default:
      console.warn("Unknown message type:", message.type);
      return false;
  }
});

// Log any native messaging errors
browser.runtime.onMessageExternal.addListener((message, sender) => {
  console.log("Received external message:", message, "from:", sender);
});

browser.runtime.onInstalled.addListener(() => {
  console.log("Extension installed/updated");
});
