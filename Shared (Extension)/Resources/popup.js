// Log when popup is loaded
console.log("Popup loaded");

/**
 * Updates the resume status text in the popup
 * @param {string} text - The text to display
 */
function updateResumeStatus(text) {
  const statusElement = document.getElementById("resume-status");
  if (statusElement) {
    statusElement.textContent = text;
  } else {
    console.error("Status element not found");
  }
}

// Request resume information from native code
browser.runtime
  .sendNativeMessage("com.riff-tech.EasyApply.Extension", {
    command: "get-resume",
  })
  .then((response) => {
    console.log("Received response:", response);
    if (response && response.filename) {
      updateResumeStatus(`Current resume: ${response.filename}`);
    } else {
      updateResumeStatus("No resume uploaded yet");
    }
  })
  .catch((error) => {
    console.error("Error fetching resume:", error);
    updateResumeStatus("Error loading resume information");
  });
