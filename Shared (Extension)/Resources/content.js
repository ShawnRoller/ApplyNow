const AI_API_URL = "https://api.openai.com/v1/chat/completions";
const AI_MODEL = "gpt-4o-mini";
const AI_SYSTEM_PROMPT =
  "You are a professional cover letter writer. Create a compelling but brief cover letter (no more than 3 paragraphs) that matches the candidate's resume to the job description. Your entire response will be copied and pasted into a cover letter, so do not use any placeholder fields.  If you do not have content for information on the cover letter, omit that information. If the fields are required for the cover letter, respond with `Cover letter missing data: ` and include the data that is missing. Do not include the candidate's address nor the current date.";
const AI_TEMP = 0.7;
const MAX_TOKENS = 1000;

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

/**
 * Error class for API calls
 */
class APIError extends Error {
  constructor(message, status, response) {
    super(message);
    this.name = "APIError";
    this.status = status;
    this.response = response;
  }
}

/**
 * Gets the resume content from the native messaging
 * @returns {Promise<string>} The resume content
 */
async function getResumeContent() {
  try {
    console.log("Requesting resume content...");
    const response = await browser.runtime.sendMessage({ type: "get-resume" });
    console.log("Received resume response:", response);
    return response.content;
  } catch (error) {
    console.error("Error getting resume content:", error);
    throw error;
  }
}

// Listen for messages from the popup
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Content script received message:", message);

  if (message.command === "get-page-content") {
    const content = extractPageContent();
    console.log("Extracted content:", content);
    sendResponse(content);
    return true;
  }

  if (message.command === "generate-cover-letter-request") {
    (async () => {
      try {
        console.log("Starting cover letter generation process...");

        console.log("Getting resume content...");
        const resumeContent = await getResumeContent();
        console.log("Resume content received:", resumeContent ? "Yes" : "No");

        if (!resumeContent) {
          console.error("No resume content available");
          sendResponse({ error: "Please upload a resume first" });
          return;
        }

        console.log("Extracting page content...");
        const content = extractPageContent();
        const jobDescription = content.mainContent || content.fullText;
        console.log(
          "Job description extracted:",
          jobDescription ? "Yes" : "No"
        );

        if (!jobDescription) {
          console.error("No job description found");
          sendResponse({
            error: "Could not extract job description from the page",
          });
          return;
        }

        const messageData = {
          type: "generate-cover-letter",
          data: {
            resume: resumeContent,
            jobDescription: jobDescription,
            systemPrompt: AI_SYSTEM_PROMPT,
          },
        };

        console.log("Sending message to background script:", messageData);
        const response = await browser.runtime.sendMessage(messageData);
        console.log("Received response from background:", response);

        if (response.error) {
          console.error("Error in response:", response.error);
          sendResponse({ error: response.error });
        } else {
          console.log("Cover letter generated successfully");
          sendResponse(response.coverLetter);
        }
      } catch (error) {
        console.error("Error in cover letter generation process:", error);
        sendResponse({ error: error.message });
      }
    })();
    return true;
  }
});
