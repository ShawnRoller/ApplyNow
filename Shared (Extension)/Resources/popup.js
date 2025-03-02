console.log("Hello World!", browser);

/**
 * Updates the resume status text in the popup
 * @param {string} text - The text to display
 */
function updateResumeStatus(text) {
  document.getElementById("resume-status").textContent = text;
}

// Request resume information from native code
browser.runtime
  .sendNativeMessage("com.riff-tech.EasyApply.Extension", {
    command: "get-resume",
  })
  .then((response) => {
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
