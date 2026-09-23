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


# Driver Safety AI

> **Real-Time On-Device Driver Monitoring & Predictive Safety Analytics Platform.**

**KIM App (Driver Safety AI)** is an advanced cross-platform Flutter application designed to enhance road safety through on-device computer vision and predictive driver analytics. By running real-time facial landmark analysis via Google ML Kit, the app continuously evaluates driver fatigue markers—including Eye Aspect Ratio (EAR) for micro-sleeps, mouth metrics for yawning, and head pose orientation for distraction—delivering sub-second audio-visual alerts without relying on internet connectivity or cloud processing.

---

## 🌟 Key Features

* 👁️ **On-Device Computer Vision Pipeline:** Fast, edge-based facial landmark processing tracking Eye Aspect Ratio (EAR), mouth-opening ratio, and 3D head posture angles (yaw, pitch, roll).
* 🚨 **Low-Latency Alert System:** Instant warning triggers powered by `safety_monitor.dart` utilizing dynamic haptics, color-shifting visual overlays, and text-to-speech Cues.
* ⚡ **Pre-Drive Wake-Up Routine:** Integrated driver readiness challenges and reaction speed tests to measure alertness before starting a route.
* 📊 **Trip Diagnostics & Historical Analytics:** Logged fatigue events, distraction frequency breakdown, and safety scoring per driving session.
* 📶 **Offline-First Architecture:** Local NoSQL storage using Hive ensures non-stop recording and analysis in remote or poor-connectivity areas.
* 🌙 **Night-Optimized UI (Cyberpunk Dark Theme):** High-contrast, low-glare neon interface designed for minimal driver eye fatigue during night trips.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (Dart `>=3.0.0`) |
| **Computer Vision / ML** | [Google ML Kit Face Detection](https://pub.dev/packages/google_mlkit_face_detection) |
| **Camera Hardware Interface** | `camera` Flutter Plugin (Live Image Streams) |
| **Local Storage** | [Hive NoSQL](https://pub.dev/packages/hive) |
| **Audio & Speech** | `flutter_tts` & `audioplayers` |
| **State Management** | Provider / Riverpod |

---

## ⚙️ ML Detection Pipeline

```text
[ Front Camera Stream ] 
          │
          ▼
 [ Camera Stream Handler ] ──► Frame Conversion (YUV420 / NV21 to InputImage)
          │
          ▼
 [ ML Kit Face Detector ]
          │
          ├──► Landmark Matrix (EAR Math)  ──► Micro-sleep / Drowsiness Detection
          ├──► Mouth Aspect Ratio          ──► Yawn Frequency Tracking
          └──► Head Rotation Angles        ──► Driver Distraction Alerts
          │
          ▼
 [ Safety Monitor Service ] ──► Trigger Audio / Speech / Haptic Alarms
          │
          ▼
 [ Local Hive Database ]   ──► Store Event Log & Generate Session Summary
```

---

## 📱 Codebase Structure (`KIM app / CODES dart`)

The codebase follows a modular architecture aligned with your `lib/` folder:

```text
lib/
├── main.dart             # Application startup, Hive initialization, & routes
├── ai/                   # ML Kit detection engine, face mesh, & mathematical models
├── core/                 # App constants, dark neon theme, & global controllers
├── database/             # Hive boxes, local storage models, & DB helper classes
├── models/               # Event logs, user settings, & trip diagnostic data models
├── screens/              # Live camera overlay, dashboard, history, & diagnostic views
├── services/             # safety_monitor.dart, camera stream handler, & TTS service
├── utils/                # EAR calculations, angle calculations, & image format converters
└── widgets/              # Neon status gauges, custom gauges, & alert dialogs
```

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio or Xcode
* Physical Android or iOS device with a front-facing camera

> ⚠️ **Hardware Requirement:** Live camera feeds and real-time ML Kit processing require physical device hardware and cannot be fully tested on desktop emulators.

---

### Installation Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/kim-driver-safety-ai.git
   cd kim-driver-safety-ai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Hive Database Adapters:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Hardware Permissions:**

   * **Android** (`android/app/src/main/AndroidManifest.xml`):
     ```xml
     <uses-permission android:name="android.permission.CAMERA" />
     <uses-permission android:name="android.permission.VIBRATE" />
     ```

   * **iOS** (`ios/Runner/Info.plist`):
     ```xml
     <key>NSCameraUsageDescription</key>
     <string>Camera access is required for real-time driver drowsiness and fatigue monitoring.</string>
     ```

5. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

1. Fork the Repository
2. Create your Feature Branch (`git checkout -b feature/NewSafetyMetric`)
3. Commit your changes (`git commit -m 'Add new fatigue detection metric'`)
4. Push to the Branch (`git push origin feature/NewSafetyMetric`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for details.
