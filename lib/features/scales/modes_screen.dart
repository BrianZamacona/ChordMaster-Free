import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/music_theory.dart';
import '../../ui/animations.dart';
import 'scales_viewmodel.dart';

/// Static data describing each of the 7 Greek modes.
class _ModeInfo {
  const _ModeInfo({
    required this.name,
    required this.degree,
    required this.type,
    required this.mood,
    required this.moodEmoji,
    required this.color,
    required this.examples,
    required this.parentNote,
  });

  final String name;
  final int degree;
  final String type;
  final String mood;
  final String moodEmoji;
  final Color color;
  final List<String> examples;
  final String parentNote;
}

const List<_ModeInfo> _modes = [
  _ModeInfo(
    name: 'Ionian',
    degree: 1,
    type: 'ionian',
    mood: 'Bright, happy, uplifting — the natural major scale',
    moodEmoji: '☀️',
    color: Colors.amber,
    examples: [
      'Beethoven — Ode to Joy',
      'John Denver — Take Me Home Country Roads',
      'Pharrell — Happy',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Dorian',
    degree: 2,
    type: 'dorian',
    mood: 'Minor with a hopeful twist — cool, jazzy, soulful',
    moodEmoji: '😎',
    color: Colors.teal,
    examples: [
      'Santana — Oye Como Va',
      'Miles Davis — So What',
      'Daft Punk — Get Lucky',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Phrygian',
    degree: 3,
    type: 'phrygian',
    mood: 'Dark, Spanish, exotic — intense and mysterious',
    moodEmoji: '🌙',
    color: Colors.deepPurple,
    examples: [
      'Metallica — Wherever I May Roam',
      'Flamenco Guitar tradition',
      'Joe Satriani — Flying in a Blue Dream',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Lydian',
    degree: 4,
    type: 'lydian',
    mood: 'Dreamy, floating, ethereal — otherworldly brightness',
    moodEmoji: '✨',
    color: Colors.cyan,
    examples: [
      'John Williams — Superman Theme',
      'The Simpsons Theme',
      'Steve Vai — For the Love of God',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Mixolydian',
    degree: 5,
    type: 'mixolydian',
    mood: 'Dominant, bluesy major — funky, rock-ready',
    moodEmoji: '🎸',
    color: Colors.orange,
    examples: [
      'Sweet Home Chicago',
      'The Beatles — Norwegian Wood',
      'Coldplay — Clocks',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Aeolian',
    degree: 6,
    type: 'aeolian',
    mood: 'Dark, emotional, melancholic — the natural minor',
    moodEmoji: '🌧️',
    color: Colors.indigo,
    examples: [
      'Led Zeppelin — Stairway to Heaven',
      'R.E.M. — Losing My Religion',
      'Pink Floyd — Another Brick in the Wall',
    ],
    parentNote: 'C',
  ),
  _ModeInfo(
    name: 'Locrian',
    degree: 7,
    type: 'locrian',
    mood: 'Dissonant, unstable, sinister — the darkest mode',
    moodEmoji: '💀',
    color: Colors.red,
    examples: [
      'Björk — Army of Me',
      'Sting — I Hung My Head',
      'Progressive metal compositions',
    ],
    parentNote: 'C',
  ),
];

/// Displays the 7 Greek modes with root selector, mood descriptions, and examples.
///
/// Intended to be used as a tab within [ScalesScreen].
class ModesScreen extends ConsumerStatefulWidget {
  /// Creates the [ModesScreen].
  const ModesScreen({super.key});

  @override
  ConsumerState<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends ConsumerState<ModesScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scalesViewModelProvider);
    final root = state.selectedRoot;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: _modes.length + 1,
      itemBuilder: (context, index) {
        if (index == _modes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Root note selector is shared with the Scales tab above.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        final mode = _modes[index];
        final isExpanded = _expandedIndex == index;
        return slideUpFade(
          _ModeCard(
            mode: mode,
            root: root,
            isExpanded: isExpanded,
            onTap: () => setState(
              () => _expandedIndex = isExpanded ? null : index,
            ),
          ),
          duration: Duration(milliseconds: 120 + index * 40),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.root,
    required this.isExpanded,
    required this.onTap,
  });

  final _ModeInfo mode;
  final String root;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = _computeNotes(root, mode.type);
    final parentScale = _parentScaleOf(root, mode.degree);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpanded
            ? BorderSide(color: mode.color, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    mode.color,
                    mode.color.withAlpha(160),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${mode.degree}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$root ${mode.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(mode.moodEmoji,
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        Text(
                          mode.mood,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // ── Notes row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: notes
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: mode.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: mode.color.withAlpha(80)),
                        ),
                        child: Text(
                          n,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: mode.color,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // ── Expanded detail ─────────────────────────────────────────
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    // Parent scale info
                    Row(
                      children: [
                        Icon(Icons.account_tree_outlined,
                            size: 14, color: mode.color),
                        const SizedBox(width: 6),
                        Text(
                          'Degree ${'I II III IV V VI VII'.split(' ')[mode.degree - 1]} of '
                          '$parentScale Major',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Famous examples
                    Text(
                      'Famous Examples',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mode.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...mode.examples.map(
                      (ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.music_note,
                                size: 12, color: mode.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ex,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Interval row
                    Text(
                      'Intervals',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mode.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _intervalsFor(mode.type)
                          .map(
                            (i) => Chip(
                              label: Text(
                                intervalNames[i] ?? '$i st',
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<String> _computeNotes(String root, String modeType) {
    final intervals = _intervalsFor(modeType);
    final rootIdx = chromaticNotes.indexOf(root);
    if (rootIdx == -1 || intervals.isEmpty) return [];
    return intervals.map((i) => chromaticNotes[(rootIdx + i) % 12]).toList();
  }

  List<int> _intervalsFor(String type) => modeFormulas[type] ?? [];

  /// Returns the root of the parent major scale for [root] at [degree].
  String _parentScaleOf(String root, int degree) {
    final rootIdx = chromaticNotes.indexOf(root);
    if (rootIdx == -1) return root;
    // The parent scale root is (root - majorScaleInterval[degree-1]) mod 12
    final majorIntervals = [0, 2, 4, 5, 7, 9, 11];
    if (degree < 1 || degree > 7) return root;
    final offset = majorIntervals[degree - 1];
    final parentIdx = (rootIdx - offset + 12) % 12;
    return chromaticNotes[parentIdx];
  }
}
