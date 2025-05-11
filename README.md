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
