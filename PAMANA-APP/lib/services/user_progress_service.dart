import 'package:hive_flutter/hive_flutter.dart';

/// Tracks badges, discovered creatures, and learning time locally via Hive.
/// Keys in the box (user_progress_box):
/// - badge:<id>            -> true
/// - discovered:<creature> -> true
/// - time_ms:<source>      -> int milliseconds (e.g., time_ms:model_viewer, time_ms:ar_viewer, time_ms:total)
/// - counter:<name>        -> int counters (e.g., quizzes_completed)
class UserProgressService {
  UserProgressService._();

  static final UserProgressService instance = UserProgressService._();

  static const String _boxName = 'user_progress_box';
  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    // Hive.initFlutter() must run in main() before this.
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> get _ensureBox => _box ?? Hive.box<dynamic>(_boxName);

  // ---------------- Badges ----------------
  Future<void> unlockBadge(String id) async {
    await _ensureBox.put('badge:$id', true);
  }

  bool hasBadge(String id) {
    return _ensureBox.get('badge:$id', defaultValue: false) == true;
  }

  Set<String> allBadges() {
    final keys = _ensureBox.keys.where((k) => k is String && (k as String).startsWith('badge:'));
    return keys.map((k) => (k as String).substring('badge:'.length)).toSet();
  }

  Stream<Set<String>> watchBadges() {
    final base = _ensureBox.watch().map((_) => allBadges());
    return Stream<Set<String>>.multi((controller) {
      controller.add(allBadges());
      final sub = base.listen(controller.add, onError: controller.addError);
      controller.onCancel = sub.cancel;
    });
  }

  // ---------------- Counters ----------------
  Future<int> incrementCounter(String name, {int by = 1}) async {
    final key = 'counter:$name';
    final current = (_ensureBox.get(key) as int?) ?? 0;
    final next = current + by;
    await _ensureBox.put(key, next);
    return next;
  }

  int getCounter(String name) {
    return (_ensureBox.get('counter:$name') as int?) ?? 0;
  }

  // ---------------- Discovery ----------------
  Future<void> markDiscovered(String creatureId) async {
    await _ensureBox.put('discovered:$creatureId', true);
  }

  bool isDiscovered(String creatureId) {
    return _ensureBox.get('discovered:$creatureId', defaultValue: false) == true;
  }

  Set<String> discoveredIds() {
    final keys = _ensureBox.keys.where((k) => k is String && (k as String).startsWith('discovered:'));
    return keys.map((k) => (k as String).substring('discovered:'.length)).toSet();
  }

  // ---------------- Time tracking ----------------
  /// Adds elapsed time to a source and to the total.
  /// Common sources: 'model_viewer', 'ar_viewer'
  Future<void> addLearningTime(Duration elapsed, {String source = 'model_viewer'}) async {
    final addMs = elapsed.inMilliseconds;
    final sourceKey = 'time_ms:$source';
    final totalKey = 'time_ms:total';
    final currentSource = (_ensureBox.get(sourceKey) as int?) ?? 0;
    final currentTotal = (_ensureBox.get(totalKey) as int?) ?? 0;
    await _ensureBox.put(sourceKey, currentSource + addMs);
    await _ensureBox.put(totalKey, currentTotal + addMs);
  }

  int getTimeMs({String source = 'total'}) {
    return (_ensureBox.get('time_ms:$source') as int?) ?? 0;
  }

  // -------- Onboarding & gating flags --------
  bool get onboardingSeen =>
      _ensureBox.get('onboarding:seen', defaultValue: false) == true;

  Future<void> setOnboardingSeen() async {
    await _ensureBox.put('onboarding:seen', true);
  }
  // -------------------------------------------

  // -------- Daily Lore helpers --------
  String get lastDailyShownDate =>
      (_ensureBox.get('daily:last_shown') as String?) ?? '';

  Future<void> setDailyShownToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _ensureBox.put('daily:last_shown', today);
  }
  // ------------------------------------

  // ---------------- Utilities ----------------
  Future<void> reset() async {
    await _ensureBox.clear();
  }
}