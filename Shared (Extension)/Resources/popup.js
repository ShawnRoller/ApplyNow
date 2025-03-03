// Log when popup is loaded
console.log("Popup loaded");

/**
 * Manages the loading state of the popup UI
 */
class LoadingStateManager {
  constructor() {
    this.overlay = document.getElementById("loading-overlay");
    this.generateButton = document.getElementById("generate-button");
    this.getContentButton = document.getElementById("get-content-button");
    this.coverLetterDisplay = document.getElementById("cover-letter-display");
    this.shareButton = document.getElementById("share-button");
  }

  /**
   * Shows the loading overlay and disables interactive elements
   */
  showLoading() {
    this.overlay.classList.remove("hidden");
    this.generateButton.disabled = true;
    this.getContentButton.disabled = true;
    this.coverLetterDisplay.disabled = true;
    this.shareButton.disabled = true;
  }

  /**
   * Hides the loading overlay and enables interactive elements
   */
  hideLoading() {
    this.overlay.classList.add("hidden");
    this.generateButton.disabled = false;
    this.getContentButton.disabled = false;
    this.coverLetterDisplay.disabled = false;
    this.shareButton.disabled = false;
  }
}

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
      updateResumeStatus(response.filename);
    } else {
      updateResumeStatus("No resume uploaded yet");
    }
  })
  .catch((error) => {
    console.error("Error fetching resume:", error);
    updateResumeStatus("Error loading resume information");
  });

/**
 * Creates a blob from the cover letter text for sharing
 * @param {string} text - The cover letter text to share
 * @returns {Blob} A blob containing the cover letter text
 */
function createCoverLetterBlob(text) {
  return new Blob([text], { type: "text/plain" });
}

/**
 * Shares the cover letter using the native share sheet
 * @param {string} coverLetterText - The text content to share
 */
async function shareCoverLetter(coverLetterText) {
  try {
    const blob = createCoverLetterBlob(coverLetterText);
    const file = new File([blob], "cover-letter.txt", { type: "text/plain" });

    if (navigator.share && navigator.canShare({ files: [file] })) {
      await navigator.share({
        files: [file],
      });
    } else {
      // Fallback for browsers that don't support native sharing
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "cover-letter.txt";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
  } catch (error) {
    console.error("Error sharing cover letter:", error);
  }
}

/**
 * Sets up event listeners for the buttons
 */
document.addEventListener("DOMContentLoaded", () => {
  const loadingManager = new LoadingStateManager();

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
      loadingManager.showLoading();
      try {
        const tab = await getCurrentTab();
        if (!tab) {
          console.error("No active tab found");
          loadingManager.hideLoading();
          return;
        }

        const response = await browser.tabs.sendMessage(tab.id, {
          command: "get-page-content",
        });

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
        console.error("Error getting page content:", error);
      } finally {
        loadingManager.hideLoading();
      }
    });
  } else {
    console.error("Get content button element not found");
  }

  // Get generate button setup
  const generateButton = document.getElementById("generate-button");
  if (generateButton) {
    generateButton.addEventListener("click", async () => {
      loadingManager.showLoading();
      try {
        const tab = await getCurrentTab();
        if (!tab) {
          console.error("No active tab found");
          loadingManager.hideLoading();
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
      } finally {
        loadingManager.hideLoading();
      }
    });
  } else {
    console.error("Generate button element not found");
  }

  // Share button setup
  const shareButton = document.getElementById("share-button");
  if (shareButton) {
    shareButton.addEventListener("click", async () => {
      const coverLetterDisplay = document.getElementById(
        "cover-letter-display"
      );
      if (coverLetterDisplay && coverLetterDisplay.value) {
        loadingManager.showLoading();
        try {
          await shareCoverLetter(coverLetterDisplay.value);
        } catch (error) {
          console.error("Error sharing cover letter:", error);
        } finally {
          loadingManager.hideLoading();
        }
      } else {
        console.error("No cover letter content to share");
      }
    });
  }
});
