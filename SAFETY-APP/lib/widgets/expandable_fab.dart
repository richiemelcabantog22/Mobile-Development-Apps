import 'package:flutter/material.dart';

class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  FabAction({required this.icon, required this.label, required this.onTap});
}

class ExpandableFab extends StatefulWidget {
  final List<FabAction> children;
  final String? heroTag;
  final Color scrimColor;

  const ExpandableFab({
    super.key,
    required this.children,
    this.heroTag,
    this.scrimColor = const Color(0x88000000),
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  bool _open = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Scrim overlay to improve contrast and close on tap
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Container(color: widget.scrimColor),
            ),
          ),
        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            minimum: const EdgeInsets.only(right: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Staggered slide-in for actions
                ...List.generate(widget.children.length, (i) {
                  final a = widget.children[i];
                  final anim = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
                    CurvedAnimation(
                      parent: _c,
                      curve: Interval(0.0 + i * 0.1, 0.7 + i * 0.1, curve: Curves.easeOut),
                    ),
                  );
                  return IgnorePointer(
                    ignoring: !_open,
                    child: AnimatedOpacity(
                      opacity: _open ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: SlideTransition(
                        position: anim,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _ActionChip(
                            icon: a.icon,
                            label: a.label,
                            onTap: () {
                              a.onTap();
                              _toggle();
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Main FAB
                FloatingActionButton(
                  heroTag: widget.heroTag,
                  onPressed: _toggle,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _open ? 0.125 : 0.0,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.14),
            border: Border.all(color: color.withOpacity(0.4)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(letterSpacing: 0.3, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
