import 'package:hive_flutter/hive_flutter.dart';
import '../models/folklore_creature.dart';

class FolkloreCreatureService {
  FolkloreCreatureService._();

  // Singleton instance for app-wide usage
  static final FolkloreCreatureService instance = FolkloreCreatureService._();

  static const String _boxName = 'folklore_creatures';
  static const String _favBoxName = 'favorites_box'; // favorites + notes
  static Box<FolkloreCreature>? _box;
  static Box<String>? _favBox;

  // Call this once at app startup
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapter if not registered yet
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FolkloreCreatureAdapter());
    }

    _box = await Hive.openBox<FolkloreCreature>(_boxName);
    // Open new favorites_box for favorites + per-creature notes
    _favBox = await Hive.openBox<String>(_favBoxName);

    // Migrate from legacy 'favorites_ids' box if present (keys only, empty notes)
    if (await Hive.boxExists('favorites_ids')) {
      final legacy = await Hive.openBox('favorites_ids');
      if (_favBox!.isEmpty && legacy.isNotEmpty) {
        for (final key in legacy.keys) {
          // Store empty note as default value
          await _favBox!.put(key as String, '');
        }
      }
      // Remove old box from disk to avoid confusion
      await legacy.deleteFromDisk();
    }
  }

  static Box<FolkloreCreature> get _ensureBox => _box ?? Hive.box<FolkloreCreature>(_boxName);
  static Box<String> get _ensureFavBox => _favBox ?? Hive.box<String>(_favBoxName);

  // Create
  Future<void> addCreature(FolkloreCreature creature) async {
    final box = _ensureBox;
    if (box.containsKey(creature.id)) {
      throw StateError('Creature with id ${creature.id} already exists.');
    }
    await box.put(creature.id, creature);
  }

  // Read
  List<FolkloreCreature> getAll() {
    final box = _ensureBox;
    return box.values.toList(growable: false);
    // Note: For large datasets consider pagination.
  }

  FolkloreCreature? getById(String id) {
    final box = _ensureBox;
    return box.get(id);
  }

  // Update (upsert)
  Future<void> updateCreature(FolkloreCreature creature) async {
    final box = _ensureBox;
    await box.put(creature.id, creature);
  }

  // Upsert convenience
  Future<void> upsertCreature(FolkloreCreature creature) async {
    final box = _ensureBox;
    await box.put(creature.id, creature);
  }

  // Delete
  Future<void> deleteCreature(String id) async {
    final box = _ensureBox;
    await box.delete(id);
    // Clean up favorites if item is deleted
    final fav = _ensureFavBox;
    if (fav.containsKey(id)) {
      await fav.delete(id);
    }
  }

  bool exists(String id) {
    final box = _ensureBox;
    return box.containsKey(id);
  }

  Future<void> clear() async {
    final box = _ensureBox;
    await box.clear();
    await _ensureFavBox.clear();
  }

  // Reactive stream of the whole list, emits current and subsequent changes.
  Stream<List<FolkloreCreature>> watchAll() {
    final box = _ensureBox;
    final baseStream = box.watch().map((_) => getAll());

    return Stream<List<FolkloreCreature>>.multi((controller) {
      controller.add(getAll()); // emit current value immediately
      final sub = baseStream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
  }

  // ---------------- Regions & Provinces helpers (for RegionalMapPage) ----------------
  // Use explicit fields on the model now.
  String _regionFor(FolkloreCreature c) => c.region;
  List<String> _provincesFor(FolkloreCreature c) => c.provinces;

  List<String> allRegions() {
    final values = _ensureBox.values;
    final regions = <String>{};
    for (final c in values) {
      final r = _regionFor(c);
      if (r.isNotEmpty && r != 'Unknown') regions.add(r);
    }
    final list = regions.toList()..sort();
    if (list.isEmpty) {
      return const ['All', 'Luzon', 'Visayas', 'Mindanao'];
    }
    return ['All', ...list];
  }

  List<String> provincesForRegion(String region) {
    final values = _ensureBox.values.where((c) => _regionFor(c) == region);
    final provs = <String>{};
    for (final c in values) {
      provs.addAll(_provincesFor(c));
    }
    final list = provs.toList()..sort();
    return ['All', ...list];
  }
  // ---------------- End Regions & Provinces helpers ----------------

  // Optional helper for profile analytics
  String regionForId(String id) {
    final c = getById(id);
    return c?.region ?? 'Unknown';
  }

  // ---------------- Grimoire: Favorites + Notes ----------------
  // In favorites_box, keys are creature IDs. Value is user's note (String).
  bool isFavorite(String id) => _ensureFavBox.containsKey(id);

  Future<void> toggleFavorite(String id) async {
    final fav = _ensureFavBox;
    if (fav.containsKey(id)) {
      await fav.delete(id);
    } else {
      // Create favorite with empty note
      await fav.put(id, '');
    }
  }

  Set<String> favoriteIds() => _ensureFavBox.keys.cast<String>().toSet();

  List<FolkloreCreature> getFavorites() {
    final ids = favoriteIds();
    return ids.map((id) => getById(id)).whereType<FolkloreCreature>().toList(growable: false);
  }

  Stream<Set<String>> watchFavoriteIds() {
    final fav = _ensureFavBox;
    final base = fav.watch().map((_) => favoriteIds());
    return Stream<Set<String>>.multi((controller) {
      controller.add(favoriteIds());
      final sub = base.listen(controller.add, onError: controller.addError);
      controller.onCancel = sub.cancel;
    });
  }

  Stream<List<FolkloreCreature>> watchFavoriteCreatures() =>
      watchFavoriteIds().map((ids) => ids.map((id) => getById(id)).whereType<FolkloreCreature>().toList(growable: false));

  // Notes APIs
  String getNote(String id) => _ensureFavBox.get(id, defaultValue: '') ?? '';

  Future<void> setNote(String id, String note) async {
    // Ensure it's in favorites
    await _ensureFavBox.put(id, note);
  }
  // --------------- End Grimoire -----------------

  // ---------------- Seed/Expand Sample Data ----------------
  Future<void> seedSampleDataIfEmpty() async {
    final box = _ensureBox;
    if (box.isNotEmpty) return;
    await upsertExpandedDataset();
  }

  /// You can call this to (re)populate the expanded curated dataset.
  /// It upserts entries so you can safely run it multiple times.
  Future<void> upsertExpandedDataset() async {
    final samples = <FolkloreCreature>[
      // Luzon
      FolkloreCreature(
        id: 'kapre',
        name: 'Kapre',
        category: 'Maligno',
        region: 'Luzon',
        provinces: const ['Quezon', 'Laguna'],
        description: '''A towering, dark-skinned tree spirit known to sit on massive branches while smoking a glowing cigar. 
Kapre are not always malevolent; they are guardians of forests and are said to play harmless tricks on travelers, such as causing them to lose their way. 
In some stories, they watch over people from afar, especially those who respect the natural world, and may even offer protection to those who honor the trees they inhabit.''',
        imageUrl: 'assets/images/kapre.png',
        modelPath: 'assets/models/kapre.glb',
        modelScale: 0.22,
      ),
      FolkloreCreature(
        id: 'tikbalang',
        name: 'Tikbalang',
        category: 'Maligno',
        region: 'Luzon',
        provinces: const ['Cordillera', 'Rizal'],
        description: '''A tall, lean humanoid with a horse’s head and hooves, often described with unnaturally long limbs and glowing eyes. 
Tikbalang are infamous for leading travelers in circles, especially in dense forests or mountain paths. 
Folklore says one can counter a Tikbalang’s tricks by wearing your shirt inside out or politely asking permission to pass. 
Some tales portray them as guardians of certain paths and forests rather than purely malicious beings.''',
        imageUrl: 'assets/images/tikbalang.png',
        modelPath: 'assets/models/tikbalang.glb',
        modelScale: 0.18,
      ),
      FolkloreCreature(
        id: 'minokawa',
        name: 'Minokawa',
        category: 'Deity',
        region: 'Luzon',
        provinces: const ['Ilocos', 'Cagayan'],
        description: '''A colossal dragon-bird said to possess steel-like feathers and a beak of diamond. 
Ancient stories claim the Minokawa attempts to devour the moon or sun, causing eclipses. 
People would bang pots and make noise to frighten it away and “bring back” the light. 
While terrifying in scale, it symbolizes the grandeur and mystery of celestial events in precolonial mythmaking.''',
        imageUrl: 'assets/images/minonakawa.jpg',
        modelPath: 'assets/models/minokawa.glb',
        modelScale: 0.28,
      ),
      FolkloreCreature(
        id: 'bungisngis',
        name: 'Bungisngis',
        category: 'Maligno',
        region: 'Luzon',
        provinces: const ['Bataan', 'Zambales'],
        description: '''A one-eyed giant recognized by its perpetual grin and booming laughter. 
Despite its frightening appearance, Bungisngis is often portrayed as more comical than cruel—easily tricked by humans in folktales. 
Its signature features—a single eye and a huge mouth—make it memorable in oral traditions passed down through generations.''',
        imageUrl: 'assets/images/Bungisngis.png',
        modelPath: 'assets/models/bungisngis.glb',
        modelScale: 0.26,
      ),
      // Visayas
      FolkloreCreature(
        id: 'manananggal',
        name: 'Manananggal',
        category: 'Aswang',
        region: 'Visayas',
        provinces: const ['Capiz', 'Aklan'],
        description: '''By day, a seemingly ordinary woman; by night, her upper torso detaches from her lower body and flies with bat-like wings. 
She is said to prey on sleeping victims using an elongated tongue, often targeting expectant mothers. 
Folklore advises using salt, garlic, or ash on the detached lower torso to prevent reattachment before dawn. 
The Manananggal’s imagery is among the most striking in Philippine horror lore.''',
        imageUrl: 'assets/images/manananggal.png',
        modelPath: 'assets/models/manananggal.glb',
        modelScale: 0.2,
      ),
      FolkloreCreature(
        id: 'sigbin',
        name: 'Sigbin',
        category: 'Maligno',
        region: 'Visayas',
        provinces: const ['Cebu', 'Bohol'],
        description: '''A hornless, goat-like creature said to walk backwards with its head lowered between its hind legs. 
It is rumored to possess an eerie, clapping sound made by its large ears and to drink the blood of victims’ shadows. 
Some stories link the Sigbin with certain Aswang clans as a companion or familiar, adding to its mystique in Visayan folklore.''',
        imageUrl: 'assets/images/sigbin.png',
        modelPath: 'assets/models/sigbin.glb',
        modelScale: 0.2,
      ),
      FolkloreCreature(
        id: 'bakunawa',
        name: 'Bakunawa',
        category: 'Deity',
        region: 'Visayas',
        provinces: const ['Cebu', 'Iloilo'],
        description: '''A massive sea serpent or dragon believed to cause eclipses by swallowing the moon. 
Older myths speak of seven moons guarding the night sky until the Bakunawa emerged; communities would create noise to drive the creature away and restore the moon’s light. 
Beyond fear, the Bakunawa represents the ocean’s power and the deep ties between natural phenomena and mythology.''',
        imageUrl: 'assets/images/bakunawa.png',
        modelPath: 'assets/models/bakunawa.glb',
        modelScale: 0.15,
      ),
      FolkloreCreature(
        id: 'dalikamata',
        name: 'Dalikamata',
        category: 'Benevolent Spirits',
        region: 'Visayas',
        provinces: const ['Aklan', 'Capiz'],
        description: '''A benevolent spirit said to be covered in countless eyes, granting her omniscient sight. 
Often associated with healing, Dalikamata sees the ailments and troubles of mortals and may offer protection or guidance. 
Her presence in Visayan lore underscores a belief in compassionate guardians within the spirit world.''',
        imageUrl: 'assets/images/dalikamata.png',
        modelPath: 'assets/models/dalikamata.glb',
        modelScale: 0.2,
      ),
      // Mindanao
      FolkloreCreature(
        id: 'sarimanok',
        name: 'Sarimanok',
        category: 'Benevolent Spirits',
        region: 'Mindanao',
        provinces: const ['Lanao del Sur'],
        description: '''A legendary Maranao bird adorned with vibrant, multicolored plumage, often depicted holding a fish in its beak or talons. 
The Sarimanok symbolizes prosperity and good fortune and is celebrated as an emblem of cultural heritage and artistry in Mindanao. 
Its ornate form translates beautifully into 3D, showcasing intricate patterns and royal symbolism.''',
        imageUrl: 'assets/images/ibonadarna.png',
        modelPath: 'assets/models/sarimanok.glb',
        modelScale: 0.22,
      ),
      FolkloreCreature(
        id: 'bata_mama',
        name: 'Bata Mama',
        category: 'Deity',
        region: 'Mindanao',
        provinces: const ['Bukidnon', 'Davao'],
        description: '''Ancestral guardian and warrior spirit invoked in some Mindanaoan traditions as a protector of people and nature. 
Stories endow Bata Mama with a strong sense of justice and a duty to maintain balance, defending those who live in harmony with their environment. 
As a deity-like figure, Bata Mama highlights the region’s emphasis on lineage, bravery, and stewardship of the land.''',
        imageUrl: 'assets/images/bata mama.png',
        modelPath: 'assets/models/bata_mama.glb',
        modelScale: 0.22,
      ),
      FolkloreCreature(
        id: 'santelmo',
        name: 'Santelmo',
        category: 'Maligno',
        region: 'Mindanao',
        provinces: const ['Zamboanga', 'Surigao'],
        description: '''A will-o’-the-wisp or ball of fire believed to be the manifestation of lost or wandering souls. 
Sightings are said to occur near rivers, marshes, or battlefields, where the spectral flame hovers or dances in place. 
The Santelmo’s glow and ethereal movement make it a compelling subject for visual effects and atmospheric storytelling.''',
        imageUrl: 'assets/images/santelmo.png',
        modelPath: 'assets/models/santelmo.glb',
        modelScale: 0.18,
      ),
      // Added: Nuno sa Punso (you mentioned its .glb was missing)
      FolkloreCreature(
        id: 'nuno_sa_punso',
        name: 'Nuno sa Punso',
        category: 'Benevolent Spirits',
        region: 'Luzon',
        provinces: const ['Bulacan', 'Pampanga'],
        description: '''A dwarf-like earth spirit who dwells in earthen mounds or anthills (punso). 
The Nuno is quick to anger when its home is disturbed: stories tell of illnesses or strange pains afflicting those who carelessly kick, sit on, or destroy a mound. 
As a rule of respect, locals ask permission (“Tabi-tabi po”) when passing through grassy or forested areas. 
When treated with reverence, the Nuno is believed to leave humans in peace.''',
        imageUrl: 'assets/images/nuno-sa-punso.png',
        modelPath: 'assets/models/nuno_sa_punso.glb',
        modelScale: 0.25,
      ),
    ];
    for (final c in samples) {
      await _ensureBox.put(c.id, c);
    }
  }
}