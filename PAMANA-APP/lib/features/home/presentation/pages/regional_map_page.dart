import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/folklore_creature_service.dart';

class RegionalMapPage extends StatefulWidget {
  const RegionalMapPage({super.key});

  @override
  State<RegionalMapPage> createState() => _RegionalMapPageState();
}

class _RegionalMapPageState extends State<RegionalMapPage> {
  String _selectedRegion = 'All';
  String _selectedProvince = 'All';

  List<String> get _regions =>
      FolkloreCreatureService.instance.allRegions().isNotEmpty
          ? FolkloreCreatureService.instance.allRegions()
          : const ['All', 'Luzon', 'Visayas', 'Mindanao'];

  List<String> get _provincesForSelected {
    if (_selectedRegion == 'All') return const ['All'];
    return FolkloreCreatureService.instance.provincesForRegion(_selectedRegion);
  }

  List<FolkloreCreature> get _filteredCreatures {
    final all = FolkloreCreatureService.instance.getAll();
    if (_selectedRegion == 'All') return all;
    final byRegion = all.where((c) => c.region == _selectedRegion);
    if (_selectedProvince == 'All') return byRegion.toList();
    return byRegion.where((c) => c.provinces.contains(_selectedProvince)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore via Regional Map'),
      ),
      body: Column(
        children: [
          // Region selector chips (horizontal scroll to avoid vertical overflow)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _regions
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(r),
                            selected: _selectedRegion == r,
                            onSelected: (_) {
                              setState(() {
                                _selectedRegion = r;
                                _selectedProvince = 'All';
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Map (with graceful fallback if asset is not present)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/philippines_map.svg',
                fit: BoxFit.contain,
                width: double.infinity,
                height: 200,
                semanticsLabel: 'Philippines Map',
                placeholderBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Philippines map not found.\nPlace assets/images/philippines_map.svg',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
          // Province/City selector as a dropdown to avoid overflow and long-text issues
          if (_selectedRegion != 'All')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedProvince,
                items: _provincesForSelected
                    .map((p) => DropdownMenuItem<String>(
                          value: p,
                          child: Text(
                            p,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedProvince = val);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Province/City',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          // Creatures list for selected region
          Expanded(
            child: _filteredCreatures.isEmpty
                ? const Center(child: Text('No creatures for this region yet.'))
                : ListView.separated(
                    itemCount: _filteredCreatures.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _filteredCreatures[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.region} • ${c.provinces.join(", ")}\n${c.description}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
