/**
 * Shows platform-specific content and extension state
 * @param {string} platform - The platform identifier ('ios' or 'mac')
 * @param {boolean} [enabled] - Whether the extension is enabled
 * @param {boolean} [useSettingsInsteadOfPreferences] - Whether to use "Settings" instead of "Preferences" in the text
 */
function show(platform, enabled, useSettingsInsteadOfPreferences) {
    document.body.classList.add(`platform-${platform}`);
    
    if (useSettingsInsteadOfPreferences) {
        document.getElementsByClassName("platform-mac state-on")[0].innerText =
        "ApplyNow's extension is currently on. You can turn it off in the Extensions section of Safari Settings.";
        document.getElementsByClassName("platform-mac state-off")[0].innerText =
        "ApplyNow's extension is currently off. You can turn it on in the Extensions section of Safari Settings.";
        document.getElementsByClassName("platform-mac state-unknown")[0].innerText =
        "You can turn on ApplyNow's extension in the Extensions section of Safari Settings.";
        document.getElementsByClassName(
                                        "platform-mac open-preferences"
                                        )[0].innerText = "Quit and Open Safari Settings…";
    }
    
    if (typeof enabled === "boolean") {
        document.body.classList.toggle(`state-on`, enabled);
        document.body.classList.toggle(`state-off`, !enabled);
    } else {
        document.body.classList.remove(`state-on`);
        document.body.classList.remove(`state-off`);
    }
}

/**
 * Opens Safari preferences
 */
function openPreferences() {
    webkit.messageHandlers.controller.postMessage("open-preferences");
}

/**
 * Triggers resume file selection
 */
function selectResume() {
    webkit.messageHandlers.controller.postMessage("select-resume");
}

/**
 * Removes the stored resume
 */
function removeResume() {
    webkit.messageHandlers.controller.postMessage("remove-resume");
}

/**
 * Updates the UI to show the current resume status
 * @param {string} filename - The name of the resume file
 */
function updateResumeStatus(filename) {
    const noResumeText = document.getElementById("no-resume-text");
    const resumeName = document.getElementById("resume-name");
    const selectButton = document.getElementById("select-resume-btn");
    const removeButton = document.getElementById("remove-resume-btn");
    
    if (filename) {
        noResumeText.style.display = "none";
        resumeName.style.display = "block";
        resumeName.textContent = filename;
        selectButton.textContent = "Change Resume";
        removeButton.style.display = "block";
    } else {
        noResumeText.style.display = "block";
        resumeName.style.display = "none";
        resumeName.textContent = "";
        selectButton.textContent = "Select Resume PDF";
        removeButton.style.display = "none";
    }
}

// Event Listeners
document
.querySelector("button.open-preferences")
.addEventListener("click", openPreferences);
document
.getElementById("select-resume-btn")
.addEventListener("click", selectResume);
document
.getElementById("remove-resume-btn")
.addEventListener("click", removeResume);
