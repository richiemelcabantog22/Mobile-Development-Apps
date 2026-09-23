# Mobile-Development-Apps
  APPS CREATED USING FLUTTER

# PAMANA (Panitikang Alaala at Mitolohiya ng Ating Nasyon)

> **Preserving Philippine Folklore through Interactive Mobile Technology.**

PAMANA is a feature-complete, cross-platform mobile application designed to preserve and promote Philippine folklore, myths, and cultural heritage. Built with modern mobile technologies, PAMANA delivers an immersive educational experience through reactive offline storage, 3D/Augmented Reality (AR) visualizations, and region-based gamified learning modules.

---

## 🌟 Key Features

* 📚 **Interactive Folklore Library:** Browse curated stories, myths, and legends categorized by Philippine regions.
* 🕶️ **3D & AR Exploration:** Visualize mythological creatures and artifacts using an integrated 3D/AR engine, complete with hardware-compatible fallback mechanisms for lower-spec devices.
* 🎮 **Gamified Learning & Quizzes:** Test your knowledge with region-based quiz banks, earn unlockable badges, and track your learning progress over time.
* 📶 **Offline-First Architecture:** Full access to downloaded folklore and quiz data without requiring an active internet connection.
* 🎨 **Material 3 Design:** Clean, adaptive UI built following modern Material Design guidelines with native support for smooth navigation.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management & Local Storage:** [Hive NoSQL](https://pub.dev/packages/hive) for fast, reactive persistence
* **Rendering Engine:** AR/3D Asset Integration with hardware-level fallback checks
* **UI/UX System:** Material Design 3 (M3)

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio or VS Code with Flutter extensions
* An Android/iOS Device or Emulator

### Installation

1. **Clone the repository:**
   ```bash
Install dependencies:

Bash
flutter pub get
Generate Hive Adapters (if modifying models):

Bash
flutter pub run build_runner build --delete-conflicting-outputs
Run the app:

Bash
flutter run
📱 Project Structure
Plaintext
lib/
├── core/            # Themes, constants, routing, and Hive initialization
├── data/            # Models, local DB schemas, and Hive adapters
├── providers/       # State management and business logic
├── views/           # UI screens (Folklore reader, AR view, Quiz system)
└── widgets/         # Reusable UI components and custom layout items
🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

📜 License
Distributed under the MIT License. See LICENSE for more information.
