browser.runtime.sendMessage({ greeting: "hello" }).then((response) => {
  console.log("Received response: ", response);
});

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("Received request: ", request);
});

/**
 * Extracts the main content from the current page
 * @returns {Object} Object containing the page title and content
 */
function extractPageContent() {
  // Get the page title
  const pageTitle = document.title;

  // Get the main content - this is a basic implementation
  // You might want to customize this based on the specific job sites you're targeting
  const content = {
    title: pageTitle,
    url: window.location.href,
    fullText: document.body.innerText,
    // You might want to add more specific selectors for job sites
    // For example, for LinkedIn job posts:
    mainContent:
      document.querySelector(".job-description")?.innerText ||
      document.body.innerText,
  };

  return content;
}

// Listen for messages from the popup
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Content script received message:", message);

  if (message.command === "get-page-content") {
    const content = extractPageContent();
    console.log("Extracted content:", content);
    sendResponse(content);
  }

  // Required for async response
  return true;
});
