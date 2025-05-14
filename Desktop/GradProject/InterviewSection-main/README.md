# Interview Service

A Flutter application that simulates technical interviews with AI-powered question generation and real-time feedback.

## Features

- 🤖 Dynamic question generation based on:
  - Selected field (e.g., iOS, Android, Web)
  - Technologies
  - Difficulty level
- 🎤 Real-time audio recording
- 🔊 Text-to-speech for question narration
- 🎙️ Speech-to-text for answer transcription
- 📊 Instant evaluation and feedback
- ⏱️ Time management for each question
- 📱 Cross-platform support (Android, iOS, Web)

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/SBAKMaged/InterviewSection.git
```

2. Navigate to the project directory:
```bash
cd InterviewSection
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── constants/     # App-wide constants and configurations
├── models/        # Data models
├── screens/       # UI screens
├── services/      # API and business logic services
├── utils/         # Utility functions and helpers
└── widgets/       # Reusable UI components
```

## Dependencies

- `record`: ^6.0.0 - Audio recording
- `permission_handler`: ^11.3.0 - Permission management
- `flutter_tts`: ^3.8.3 - Text-to-speech
- `speech_to_text`: ^7.0.0 - Speech recognition
- `http`: ^1.1.0 - API communication

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped shape this project

## Recent Changes (AI Assistant Session)

### Bug Fixes & Improvements
- **Microphone Permission (iOS):**
  - Ensured `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` are present in `ios/Runner/Info.plist`.
  - Updated `ios/Podfile` to add the `PERMISSION_MICROPHONE=1` preprocessor definition for proper permission handling with `permission_handler`.
  - Ran `pod install` and cleaned/rebuilt the project to apply changes.
- **Text-to-Speech (TTS) Speed:**
  - Lowered the TTS speech rate in `lib/screens/interview_screen.dart` for a more natural voice experience.
- **API Key Management:**
  - Updated both `lib/services/api_service.dart` and `lib/services/fixed_api_service.dart` to use a new, valid OpenRouter API key for dynamic question generation and answer evaluation.
  - Provided instructions for users to obtain and securely set their own API key.
- **API Integration:**
  - Verified OpenRouter API status and ensured the app now generates unique, relevant interview questions from the API.
- **General:**
  - Cleaned and rebuilt the project to ensure all changes are applied.

### How to Push as a New Branch
1. **Create a new branch:**
   ```bash
   git checkout -b feature/ai-assistant-fixes
   ```
2. **Add and commit your changes:**
   ```bash
   git add .
   git commit -m "Apply AI assistant fixes: iOS permissions, TTS speed, OpenRouter API integration, and bug fixes"
   ```
3. **Push the branch to your remote repository:**
   ```bash
   git push origin feature/ai-assistant-fixes
   ```
4. **Open a Pull Request** on GitHub to merge your changes.

---
If you need to update your OpenRouter API key, edit the following files:
- `lib/services/api_service.dart`
- `lib/services/fixed_api_service.dart`

Replace the value of `_apiKey` with your own key from https://openrouter.ai/
