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

/**
 * Gets the current active tab
 * @returns {Promise<browser.tabs.Tab>} The current active tab
 */
async function getCurrentTab() {
  const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
  return tab;
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

/**
 * Sets up event listeners for the buttons
 */
document.addEventListener("DOMContentLoaded", () => {
  // Test button setup
  const testButton = document.getElementById("test-button");
  if (testButton) {
    testButton.addEventListener("click", () => {
      console.log("Test button clicked!");
    });
  } else {
    console.error("Test button element not found");
  }

  // Get content button setup
  const getContentButton = document.getElementById("get-content-button");
  if (getContentButton) {
    getContentButton.addEventListener("click", async () => {
      try {
        const tab = await getCurrentTab();
        if (!tab) {
          console.error("No active tab found");
          return;
        }

        const response = await browser.tabs.sendMessage(tab.id, {
          command: "get-page-content",
        });

        console.log("Page content received:", response);
      } catch (error) {
        console.error("Error getting page content:", error);
      }
    });
  } else {
    console.error("Get content button element not found");
  }

  // Get generate button setup
  const generateButton = document.getElementById("generate-button");
  if (generateButton) {
    generateButton.addEventListener("click", async () => {
      try {
        const tab = await getCurrentTab();
        if (!tab) {
          console.error("No active tab found");
          return;
        }

        const response = await browser.tabs.sendMessage(tab.id, {
          command: "generate-cover-letter",
        });

        console.log("Cover letter received:", response);
        // Display the generated cover letter
        const coverLetterDisplay = document.getElementById(
          "cover-letter-display"
        );
        if (coverLetterDisplay && response) {
          coverLetterDisplay.textContent =
            typeof response === "string"
              ? response
              : JSON.stringify(response, null, 2);
        }
      } catch (error) {
        console.error("Error getting cover letter:", error);
      }
    });
  } else {
    console.error("Generate button element not found");
  }
});
