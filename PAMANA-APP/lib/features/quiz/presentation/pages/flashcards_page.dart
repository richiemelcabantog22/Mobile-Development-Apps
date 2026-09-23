import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../ar_viewer/presentation/pages/model_viewer_page.dart';

// Curated multi-line prompts per creature to enrich flashcard front content
const Map<String, List<String>> curatedFlashcardPrompts = {
  'kapre': [
    'Often seen atop Balete trees at dusk.',
    'Sometimes protects respectful travelers.',
    'Known for a glowing cigar visible in the dark.',
    'A guardian rather than a predator in some tales.',
    'Forest trickster: causes wanderers to lose their way.',
  ],
  'tikbalang': [
    'Tall, lean frame with horse head and hooves.',
    'Notorious for leading travelers astray on mountain paths.',
    'Turn your shirt inside out to pass safely.',
    'May be a guardian of certain trails.',
    'Glowing eyes in folklore accounts.',
  ],
  'nuno_sa_punso': [
    'Dwells in earthen mounds or anthills.',
    'Easily angered if its home is disturbed.',
    'Say “Tabi-tabi po” to show respect.',
    'Afflicts the disrespectful with illness or pain.',
    'Peaceful when treated reverently.',
  ],
  'minokawa': [
    'Colossal bird-dragon with steel-like feathers.',
    'Diamond beak from ancient lore.',
    'Associated with eclipses in myth.',
    'Communities bang pots to scare it away.',
    'Celestial-scale creature: swallows the moon.',
  ],
  'bungisngis': [
    'Cyclops giant with a perpetual grin.',
    'More comical than cruel in folktales.',
    'Easily tricked by clever humans.',
    'Booming laughter echoes across hills.',
    'Iconic one-eyed visage in oral traditions.',
  ],
  'manananggal': [
    'Upper torso detaches at night to fly.',
    'Trails viscera, bat-like wings spread wide.',
    'Targets sleeping victims with elongated tongue.',
    'Salt, garlic, or ash hinder reattachment.',
    'Returns before dawn to recombine with lower half.',
  ],
  'sigbin': [
    'Walks backward with head lowered between hind legs.',
    'Claps large ears to make eerie sounds.',
    'Rumored companion of certain Aswang clans.',
    'Drinks the blood of shadows in some tales.',
    'Cryptid-like presence in Visayan lore.',
  ],
  'bakunawa': [
    'Sea serpent tied to lunar eclipses.',
    'Famed for swallowing the seven moons.',
    'Communities make noise to restore light.',
    'Symbol of ocean’s power in mythology.',
    'Grand “boss-level” creature in lore.',
  ],
  'dalikamata': [
    'Benevolent spirit covered in many eyes.',
    'Omniscient sight grants protective insight.',
    'Associated strongly with healing.',
    'Watches human actions compassionately.',
    'Guides mortals toward wellness.',
  ],
  'sarimanok': [
    'Regal Maranao bird with vibrant feathers.',
    'Often depicted carrying a fish.',
    'Symbol of prosperity and cultural artistry.',
    'Radiant colors and ornate patterns.',
    'Emblem of good fortune in Mindanao.',
  ],
  'bata_mama': [
    'Ancestral guardian and warrior spirit.',
    'Defends those in harmony with nature.',
    'Represents justice and stewardship.',
    'Epic traditions venerate this protector.',
    'Lineage and bravery central to stories.',
  ],
  'santelmo': [
    'Will-o’-the-wisp: wandering ball of fire.',
    'Manifestation of lost or wandering souls.',
    'Seen near rivers, marshes, or battlefields.',
    'Hovers or dances in spectral patterns.',
    'Strong atmospheric presence in folklore.',
  ],
};

class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> with SingleTickerProviderStateMixin {
  final _service = FolkloreCreatureService.instance;
  late List<FolkloreCreature> _deck;
  int _index = 0;

  late AnimationController _controller;
  // 0.0 = front, 1.0 = back
  late Animation<double> _flip;
  bool _revealMore = false;

  @override
  void initState() {
    super.initState();
    _deck = List<FolkloreCreature>.from(_service.getAll());
    _deck.shuffle();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _flip = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  List<String> _buildHintLines(FolkloreCreature c) {
    final hints = <String>[];
    if (c.region.isNotEmpty && c.region != 'Unknown') hints.add('Region: ${c.region}');
    if (c.category.isNotEmpty && c.category != 'Unknown') hints.add('Category: ${c.category}');
    if (c.provinces.isNotEmpty) hints.add('Provinces: ${c.provinces.join(", ")}');
    // Add a lore-style clue line
    if (c.id == 'manananggal') hints.add('Clue: Night flyer with a secret on the ground.');
    if (c.id == 'tikbalang') hints.add('Clue: Turn your shirt inside out to pass.');
    if (c.id == 'kapre') hints.add('Clue: Smoke signals from the trees.');
    if (c.id == 'bakunawa' || c.id == 'minokawa') hints.add('Clue: Celestial events explained in myth.');
    if (c.id == 'nuno_sa_punso') hints.add('Clue: “Tabi-tabi po” shows respect.');
    if (c.id == 'sigbin') hints.add('Clue: Backward steps, forward fear.');
    if (c.id == 'bungisngis') hints.add('Clue: A laugh that echoes in the hills.');
    if (c.id == 'sarimanok') hints.add('Clue: A royal bird bearing fortune.');
    if (c.id == 'santelmo') hints.add('Clue: A flame that wanders and watches.');
    return hints;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isFront => _controller.value < 0.5;

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _nextCard() {
    if (_deck.isEmpty) return;
    setState(() {
      _index = (_index + 1) % _deck.length;
    });
    // Always show front first when moving to next
    _controller.value = 0.0;
  }

  void _prevCard() {
    if (_deck.isEmpty) return;
    setState(() {
      _index = (_index - 1 + _deck.length) % _deck.length;
    });
    _controller.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_deck.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No creatures available for review yet.')),
      );
    }
    final c = _deck[_index];
    final hint = c.description.isNotEmpty
        ? c.description.length > 140
            ? '${c.description.substring(0, 140)}…'
            : c.description
        : 'Guess the creature from its lore…';
    final extraHints = _revealMore ? _buildHintLines(c) : const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            tooltip: 'Shuffle',
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              setState(() {
                _deck.shuffle();
                _index = 0;
              });
              _controller.value = 0.0;
            },
          ),
          IconButton(
            tooltip: _revealMore ? 'Hide extra hints' : 'Show extra hints',
            icon: Icon(_revealMore ? Icons.tips_and_updates : Icons.tips_and_updates_outlined),
            onPressed: () => setState(() => _revealMore = !_revealMore),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            // Progress
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / _deck.length,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_index + 1}/${_deck.length}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Flip card
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flip,
                    builder: (context, child) {
                      final angle = _flip.value * math.pi; // 0..pi
                      final isFront = angle <= math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.88,
                          height: MediaQuery.of(context).size.height * 0.48,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Front (hint)
                              IgnorePointer(
                                ignoring: !isFront,
                                child: Opacity(
                                  opacity: isFront ? 1 : 0,
                                  child: _FlashSide(
                                    gradient: [cs.primaryContainer, cs.primary.withOpacity(0.85)],
                                    title: 'Who am I?',
                                    body: hint,
                                    extraLines: extraHints,
                                    footer: 'Tap to reveal',
                                    icon: Icons.help_center_rounded,
                                    thumbnailPath: c.imageUrl.isNotEmpty ? c.imageUrl : null,
                                  ),
                                ),
                              ),
                              // Back (answer)
                              IgnorePointer(
                                ignoring: isFront,
                                child: Opacity(
                                  opacity: isFront ? 0 : 1,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(math.pi), // correct mirrored back
                                    child: _AnswerSide(
                                      name: c.name,
                                      region: c.region,
                                      category: c.category,
                                      provinces: c.provinces,
                                      thumbnailPath: c.imageUrl.isNotEmpty ? c.imageUrl : null,
                                      onView3D: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => ModelViewerPage(creature: c)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Controls
            Row(
              children: [
                IconButton.outlined(
                  onPressed: _prevCard,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _flipCard,
                    child: Text(_isFront ? 'Reveal' : 'Hide'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Self-assessment buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _nextCard,
                    icon: const Icon(Icons.thumb_down_alt_outlined),
                    label: const Text("I didn't know"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _nextCard,
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('I knew it'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashSide extends StatelessWidget {
  final List<Color> gradient;
  final String title;
  final String body;
  final List<String> extraLines;
  final String footer;
  final IconData icon;
  final String? thumbnailPath;

  const _FlashSide({
    required this.gradient,
    required this.title,
    required this.body,
    this.extraLines = const <String>[],
    required this.footer,
    required this.icon,
    this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Optional semi-transparent thumbnail silhouette
          if (thumbnailPath != null)
            Opacity(
              opacity: 0.16,
              child: Image.asset(
                thumbnailPath!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.12),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                // Scrollable body + extra hints to avoid clipping long text
                Expanded(
                  child: Scrollbar(
                    interactive: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                            softWrap: true,
                          ),
                          if (extraLines.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...extraLines.take(10).map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: Colors.white70)),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    footer,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerSide extends StatelessWidget {
  final String name;
  final String region;
  final String category;
  final List<String> provinces;
  final String? thumbnailPath;
  final VoidCallback onView3D;

  const _AnswerSide({
    required this.name,
    required this.region,
    required this.category,
    required this.provinces,
    required this.onView3D,
    this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailPath != null)
            Opacity(
              opacity: 0.10,
              child: Image.asset(
                thumbnailPath!,
                fit: BoxFit.cover,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.surfaceBright, cs.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 28),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.public, label: region),
                    _MetaChip(icon: Icons.category_outlined, label: category),
                    if (provinces.isNotEmpty)
                      _MetaChip(icon: Icons.location_on_outlined, label: provinces.join(', ')),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 46,
                  child: FilledButton.tonalIcon(
                    onPressed: onView3D,
                    icon: const Icon(Icons.threed_rotation),
                    label: const Text('View 3D'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
