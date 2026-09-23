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


---
---

Driver Safety AI (KIM App)

Real-Time On-Device Driver Monitoring & Safety Analytics Platform.

Driver Safety AI is an advanced Flutter-based cross-platform mobile application engineered to enhance road safety through real-time driver monitoring, computer vision, and predictive safety analytics. Utilizing on-device Machine Learning via Google ML Kit, the app monitors driver facial metrics in real time to detect signs of fatigue, drowsiness (via Eye Aspect Ratio), yawning, and distraction—triggering instant audio-visual alerts and logging safety events without requiring cloud dependence.

🌟 Key Features

👁️ On-Device Computer Vision Pipeline: High-frequency facial landmark analysis tracking Eye Aspect Ratio (EAR) for micro-sleeps, mouth open ratios for yawning, and head pose/orientation angles for distraction.

🚨 Real-Time Alert System: Low-latency audio and visual warnings managed by safety_monitor.dart and integrated haptic feedback when risk thresholds are breached.

⏱️ Pre-Drive Wake-Up & Reaction Tests: Integrated pre-drive assessment routines and reaction time challenges to gauge driver alertness before starting a session.

📊 Trip Diagnostics & Session History: Comprehensive session summaries, historical logging of fatigue/distraction events, and driving stability trends.

📶 Offline-First Architecture: Local storage powered by Hive ensures full functionality in dead zones and remote locations.

🎨 Cyberpunk / Dark Neon UI: Dark-mode optimized interface designed specifically for night driving to reduce driver glare and distraction.

🛠️ Architecture & Tech Stack

Framework: Flutter (Dart)

Computer Vision & ML: Google ML Kit Face Detection

Camera Stream Handler: camera plugin with live image stream processing

Local Data Persistence: Hive NoSQL for fast event and session logging

Audio & Speech: flutter_tts & audioplayers for voice prompts and alert cues

State Management: Provider / Riverpod

⚙️ System Workflow

[ Camera Stream ] 
       │
       ▼
[ Image Stream Handler ] ──(Format Conversion)
       │
       ▼
[ ML Kit Face Detector ]
       │
       ├──► Landmark Extract (EAR Calculation) ──► Drowsiness Detection
       ├──► Mouth Landmark Ratio               ──► Yawn Detection
       └──► Head Rotation Angles (Yaw/Pitch)    ──► Distraction Check
       │
       ▼
[ Safety Monitor Service ] ──(Threshold Exceeded)──► [ Audio / TTS / Haptic Alert ]
       │
       ▼
[ Hive Local DB Storage ] ──► [ Dashboard / Session Diagnostics ]


🚀 Getting Started

Prerequisites

Flutter SDK (>= 3.0.0)

Dart SDK

Android Studio / Xcode

Physical mobile device (Android/iOS) with front-facing camera support

Note: Real-time ML Kit camera streams require physical mobile hardware and cannot be properly evaluated on desktop emulators.

Installation & Setup

Clone the repository:

git clone https://github.com/your-username/driver-safety-ai.git
cd driver-safety-ai


Install dependencies:

flutter pub get


Generate Hive Adapters:

flutter pub run build_runner build --delete-conflicting-outputs


Configure Device Permissions:

Android (android/app/src/main/AndroidManifest.xml):

<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />


iOS (ios/Runner/Info.plist):

<key>NSCameraUsageDescription</key>
<string>Camera access is required for real-time driver fatigue and drowsiness monitoring.</string>


Run on a physical device:

flutter run


📱 Project Directory Structure

lib/
├── main.dart             # Application entry point & service initialization
├── ai/                   # ML Kit detection engine & face mesh handlers
├── core/                 # App constants, theme configuration, audio/haptic triggers
├── database/             # Hive box setup & local database access objects
├── models/               # Event logs, user preferences, and session models
├── screens/              # Dashboard, live monitoring overlay, history, diagnostics
├── services/             # Safety monitor service, camera stream handler, TTS
├── utils/                # Mathematical helpers (EAR, mouth ratio, angle math)
└── widgets/              # Neon panel containers, status gauges, alert dialogs


🤝 Contributing

Fork the Repository

Create a Feature Branch (git checkout -b feature/NewMetric)

Commit your Changes (git commit -m 'Add new distraction metric')

Push to the Branch (git push origin feature/NewMetric)

Open a Pull Request

📜 License

Distributed under the MIT License. See LICENSE for details.
