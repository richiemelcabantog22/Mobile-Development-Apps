class AppConstants {
  // Drowsiness thresholds (defaults)
  static const double eyeClosedThreshold = 0.35; 
  static const int eyeClosedDurationMs = 1500;   
  static const double headTiltThresholdDeg = 45;

  // Blink thresholds
  static const double blinkClosedThreshold = 0.25;
  static const int blinkMinClosedMs = 50;
  static const int blinkMaxClosedMs = 400;

  // Hive box names
  static const String historyBox = 'drowsiness_records_box';
  static const String settingsBox = 'settings_box';
  static const String preDriveBox = 'pre_drive_results_box';
  static const String prefsBox = 'ui_prefs_box'; // ADD

  // Landmark-based thresholds (EAR/MAR/PERCLOS)
  static const double earClosedThreshold = 0.19;       // typical EAR close threshold
  static const int perclosWindowSeconds = 60;          // rolling window
  static const double perclosAlertThreshold = 0.35;    // >35% eyes closed => risk

  // Dizziness fusion thresholds
  static const double swayAmplitudeDeg = 10.0;         // head roll sway amplitude threshold
  static const double swayFreqHz = 0.25;               // rhythmic sway frequency (approx)
  static const double dizzinessAlertScore = 0.7;       // 0..1 scaled score to alert

  static const String appTitle =
      'AI-POWERED DRIVER SAFETY SYSTEM: A FACE RECOGNITION APPLICATION FOR SLEEPINESS AND DIZZINESS DETECTION WITH REAL-TIME ALERTS';
}
