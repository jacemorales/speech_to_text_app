# 🎤 Speech to Text App (Flutter Edition)

A modern, sleek, and highly interactive **Flutter application** that converts speech to text in real-time. Features fluid animations, local persistence, category tagging, search, copy/share capabilities, and fallback demo simulation.

---

## ⚡ Features

- **Real-Time Speech Recognition**: Seamless live voice-to-text conversion.
- **Demo Simulation Mode**: Automatic simulation fallback when voice input is unavailable or denied on web/desktop.
- **Multi-Language Support**: Switch easily between 10+ supported spoken languages.
- **Interactive Audio Visualizer**: Dynamic visualizer bars and glowing pulsing mic button when recording.
- **Local Persistence**: Save, edit, search, favorite, and delete transcripts locally using `shared_preferences`.
- **Modern Material 3 UX**: Clean dark & light modes, rich typography, smooth animations (`flutter_animate`), and dynamic note statistics (word & character count).

---

## 🛠 Tech Stack

- **Framework**: Flutter (Dart 3)
- **State & UI**: Material 3 Design, Google Fonts, Flutter Animate
- **Speech Engine**: `speech_to_text`
- **Storage**: `shared_preferences`

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)

### Run the App

```bash
# Fetch dependencies
flutter pub get

# Run on available device or browser
flutter run
```

### Run Tests

```bash
flutter test
```
