import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../ar_viewer/presentation/pages/ar_viewer_page.dart';
import '../../../ar_viewer/presentation/pages/model_viewer_page.dart';
import '../widgets/creature_of_the_day_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedRegion = 'All';

  List<FolkloreCreature> _allCreatures = [];
  List<FolkloreCreature> _filteredCreatures = [];
  Set<String> _favoriteIds = {};

  StreamSubscription<Set<String>>? _favSub;

  final List<String> _categories = [
    'All',
    'Maligno',
    'Aswang',
    'Deity',
    'Benevolent Spirits',
  ];

  final List<String> _regions = [
    'All',
    'Luzon',
    'Visayas',
    'Mindanao',
  ];

  @override
  void initState() {
    super.initState();
    _loadCreatures();
    _searchController.addListener(_applyFilters);
    _favSub = FolkloreCreatureService.instance.watchFavoriteIds().listen((ids) {
      setState(() => _favoriteIds = ids);
    });
  }

  Future<void> _loadCreatures() async {
    final creatures = FolkloreCreatureService.instance.getAll();
    setState(() {
      _allCreatures = creatures;
      _filteredCreatures = creatures;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCreatures = _allCreatures.where((creature) {
        final matchesSearch = creature.name.toLowerCase().contains(query) ||
            creature.description.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' ||
            (creature.category.toLowerCase() == _selectedCategory.toLowerCase());
        final matchesRegion = _selectedRegion == 'All' ||
            (creature.region.toLowerCase() == _selectedRegion.toLowerCase());
        return matchesSearch && matchesCategory && matchesRegion;
      }).toList();
    });
  }

  FolkloreCreature? getCreatureOfTheDay() {
    if (_allCreatures.isEmpty) return null;
    final dayIndex = DateTime.now().day % _allCreatures.length;
    return _allCreatures[dayIndex];
  }

  // Safe Fallback Dialog to show when AR services throw exceptions or fail
  void _showARUnsupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 10),
            Text('AR Not Supported'),
          ],
        ),
        content: const Text(
          'Your device does not support or have AR Google Play Services enabled. '
          'You can still explore this creature seamlessly using our Interactive 3D Model Viewer instead!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creatureOfTheDay = getCreatureOfTheDay();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Featured Section
            if (creatureOfTheDay != null)
              SliverToBoxAdapter(
                child: CreatureOfTheDayCard(creature: creatureOfTheDay),
              ),

            // 2. Search Text Input Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search creatures...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Dropdown Filtering Controls Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              _applyFilters();
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        items: _regions
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRegion = val;
                              _applyFilters();
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Region',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Dynamic Grid Output
            _filteredCreatures.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No creatures found.')),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72, // Fixed: vertical space expanded to prevent layout overflow
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final c = _filteredCreatures[index];
                          return _CreatureCard(
                            creature: c,
                            isFavorite: _favoriteIds.contains(c.id),
                            onToggleFavorite: () =>
                                FolkloreCreatureService.instance.toggleFavorite(c.id),
                            onOpen3D: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => ModelViewerPage(creature: c)),
                              );
                            },
                            onTryAR: () {
                              try {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ARViewerPage(creature: c)),
                                ).catchError((error) {
                                  debugPrint('AR Route Navigation Exception: $error');
                                  _showARUnsupportedDialog(context);
                                });
                              } catch (e) {
                                debugPrint('AR Initialization Crash Blocked: $e');
                                _showARUnsupportedDialog(context);
                              }
                            },
                          );
                        },
                        childCount: _filteredCreatures.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _CreatureCard extends StatelessWidget {
  final FolkloreCreature creature;
  final VoidCallback onOpen3D;
  final VoidCallback onTryAR;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _CreatureCard({
    required this.creature,
    required this.onOpen3D,
    required this.onTryAR,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen3D,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cs.surfaceContainerHighest, cs.surfaceVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: creature.imageUrl.isNotEmpty
                  ? Image.asset(
                      creature.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : CircleAvatar(
                      radius: 32,
                      backgroundColor: cs.primary.withOpacity(0.12),
                      child: Text(
                        creature.name.isNotEmpty ? creature.name[0] : '?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: cs.primary),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              creature.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            
            // Fixed: Wrapped inside Expanded to scale body content safely instead of pushing components down
            Expanded(
              child: Text(
                creature.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onOpen3D,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('3D View', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.filledTonal(
                    onPressed: onTryAR,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Try AR (beta)',
                    icon: const Icon(Icons.view_in_ar, size: 18),
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