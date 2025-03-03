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
 * Generates a cover letter based on the resume and job description using OpenAI API
 * @param {Object} params - The parameters for generating the cover letter
 * @param {string} params.resume - The resume content
 * @param {string} params.jobDescription - The job description content
 * @returns {Promise<string>} The generated cover letter
 * @throws {APIError} If the API request fails
 */
async function generateCoverLetter({ resume, jobDescription }) {
  // TODO: Move these to a secure configuration
  const config = {
    apiKey: "YOUR_API_KEY", // This should be stored securely and injected
    model: "gpt-4o-mini",
    temperature: 0.7,
    maxTokens: 1000,
  };

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify({
        model: config.model,
        messages: [
          {
            role: "system",
            content:
              "You are a professional cover letter writer. Create a compelling cover letter that matches the candidate's resume to the job description.",
          },
          {
            role: "user",
            content: `Please write a cover letter for the following job description:\n\n${jobDescription}\n\nBased on this resume:\n\n${resume}`,
          },
        ],
        temperature: config.temperature,
        max_tokens: config.maxTokens,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => null);
      throw new APIError(
        `API request failed with status ${response.status}`,
        response.status,
        errorData
      );
    }

    const data = await response.json();
    const coverLetter = data.choices?.[0]?.message?.content;

    if (!coverLetter) {
      throw new APIError("No cover letter content received from API");
    }

    return coverLetter;
  } catch (error) {
    if (error instanceof APIError) {
      throw error;
    }
    throw new APIError(
      `Failed to generate cover letter: ${
        error instanceof Error ? error.message : "Unknown error"
      }`,
      undefined,
      error
    );
  }
}

// Listen for messages from the popup
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Content script received message:", message);

  if (message.command === "get-page-content") {
    const content = extractPageContent();
    console.log("Extracted content:", content);
    sendResponse(content);
  }

  if (message.command === "generate-cover-letter") {
    // Handle async operation properly
    generateCoverLetter({
      resume: "test123",
      jobDescription: "test123",
    })
      .then((coverLetter) => {
        console.log("Generated Cover Letter:", coverLetter);
        sendResponse(coverLetter);
      })
      .catch((error) => {
        console.error("Error generating cover letter:", error);
        sendResponse({ error: error.message });
      });
  }

  // Required for async response
  return true;
});
