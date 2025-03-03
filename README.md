# ApplyNow - AI-Powered Cover Letter Generator

ApplyNow is a Safari extension for macOS, iOS, and iPadOS that helps you generate customized cover letters using AI, based on your resume and the job descriptions you're viewing. The extension uses OpenAI's API to create tailored cover letters that you can easily export and use in your job applications.

> 🎉 **Coming Soon**: ApplyNow will be available on TestFlight for easier installation and testing!

## Features

- 📱 Works across Apple devices (macOS, iOS, iPadOS)
- 🤖 AI-powered cover letter generation
- 📄 Resume-aware personalization
- 📋 Easy export functionality
- 🔒 Secure (uses your own OpenAI API key)

## Prerequisites

Before you begin, ensure you have the following:

- macOS device (for development)
- Xcode 14.0 or later
- An OpenAI API key ([Get one here](https://platform.openai.com/api-keys))
- Your resume in .txt format
- Safari 14.0 or later
- Apple Developer Account (free or paid)

## Installation

### 1. Configure Development Settings

1. Sign in to your Apple Developer account in Xcode:

   - Open Xcode
   - Go to Xcode > Settings > Accounts
   - Click '+' and add your Apple ID
   - Select your Apple ID and click "Manage Certificates"
   - Click '+' to create a new Apple Development certificate if needed

2. Configure App Group and Signing:
   - In Xcode, select the project navigator
   - Select the ApplyNow project
   - For each target (ApplyNow and Safari Extension):
     - Select the target
     - Under "Signing & Capabilities":
       - Select your Team
       - Update the Bundle Identifier if needed
       - Ensure "App Groups" capability is added
       - Add the app group: `group.com.yourdomain.applynow`
       - Let Xcode automatically manage signing

### 2. Clone and Configure

1. Clone this repository:

   ```bash
   git clone https://github.com/ShawnRoller/ApplyNow.git
   cd ApplyNow
   ```

2. Open the project in Xcode:

   ```bash
   open ApplyNow.xcodeproj
   ```

3. Add your OpenAI API key:
   - Open `content.js`
   - Locate the API key configuration section
   - Replace `YOUR_API_KEY` with your actual OpenAI API key

### 3. Build and Install

#### For macOS:

1. In Xcode, select "macOS" as your target device
2. Click the "Run" button or press `Cmd + R`
3. Open Safari
4. Go to Safari Preferences > Extensions
5. Enable the "ApplyNow" extension

#### For iOS/iPadOS:

1. In Xcode, select your iOS/iPadOS device as the target
2. Click the "Run" button or press `Cmd + R`
3. On your device:
   - Open Settings
   - Scroll down to Safari
   - Tap Extensions
   - Enable "ApplyNow"

## Usage

1. Launch the ApplyNow app
2. Select your resume (.txt format) when prompted
3. Navigate to any job posting in Safari
4. Click the ApplyNow extension icon in Safari
5. Review and customize the generated cover letter
6. Export your cover letter in your preferred format

## Privacy and Security

- Your OpenAI API key is stored locally
- Resume data is processed locally
- Job description data is only sent to OpenAI for cover letter generation
- No data is stored on external servers

## Troubleshooting

### Common Issues

1. Extension not appearing in Safari:

   - Ensure the extension is enabled in Safari preferences
   - Try restarting Safari

2. API errors:

   - Verify your OpenAI API key is correctly configured
   - Check your API usage limits

3. Code Signing Issues:
   - Ensure you're signed in to Xcode with your Apple ID
   - Verify that automatic signing is enabled
   - Check that the bundle identifier is unique
   - Make sure the app group identifier matches in all targets

### iOS/iPadOS Specific

If the extension isn't appearing:

1. Open Settings
2. Navigate to Safari > Extensions
3. Ensure ApplyNow is enabled
4. If needed, tap on ApplyNow to configure permissions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Support

For issues and feature requests, please [open an issue](https://github.com/ShawnRoller/ApplyNow/issues) on GitHub.
