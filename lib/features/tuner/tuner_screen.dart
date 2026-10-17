import 'dart:math' as math;

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/widgets/donation_button.dart';
import 'package:chordmaster_free/core/widgets/tool_switcher.dart';
import 'package:chordmaster_free/services/achievement_service.dart';
import 'package:chordmaster_free/ui/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tuner_viewmodel.dart';

class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  bool _achievementGranted = false;

  /// Guardado al iniciar: en `dispose` ya no se puede usar `ref`.
  late final TunerViewModel _vm;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _vm = ref.read(tunerViewModelProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El shell deja montadas las pestañas ocultas (TickerMode desactivado):
    // el micrófono solo se usa mientras el afinador está a la vista.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_listening) {
      _listening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _listening) _vm.startListening();
      });
    } else if (!visible && _listening) {
      _listening = false;
      _vm.stopListening();
    }
  }

  @override
  void dispose() {
    if (_listening) _vm.stopListening();
    super.dispose();
  }

  void _maybeUnlockAchievement(bool isInTune) {
    if (_achievementGranted || !isInTune) return;
    _achievementGranted = true;
    AchievementService.instance.unlock('tuned_up').catchError((e) {
      debugPrint('TunerScreen achievement error: $e');
    });
  }

  Color _needleColor(double? cents) {
    if (cents == null) return context.palette.textDisabled;
    final abs = cents.abs();
    if (abs < 5) return context.palette.success;
    if (abs < 20) return context.palette.warning;
    return context.palette.error;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tunerViewModelProvider);

    if (state.isInTune) _maybeUnlockAchievement(true);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        bottom: const ToolSwitcher(current: AppTool.tuner),
        title: const Text(AppStrings.toolsTitle),
        iconTheme: IconThemeData(color: context.palette.textPrimary),
      ),
      body: !state.hasPermission
          ? _PermissionDeniedView(
              onGrant: () =>
                  ref.read(tunerViewModelProvider.notifier).startListening(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _NeedleGauge(
                    cents: state.cents,
                    color: _needleColor(state.cents),
                  ),
                  const SizedBox(height: 16),
                  _NoteDisplay(state: state),
                  const SizedBox(height: 24),
                  _ReferenceChips(
                    current: state.referenceHz,
                    onSelect: (hz) => ref
                        .read(tunerViewModelProvider.notifier)
                        .setReference(hz),
                  ),
                  const SizedBox(height: 24),
                  const _GuitarStringsRow(),
                  const SizedBox(height: 32),
                  const DonationButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off, color: context.palette.error, size: 64),
              const SizedBox(height: 16),
              Text(
                'Microphone access is required to use the tuner. Please grant permission.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onGrant,
                icon: const Icon(Icons.mic),
                label: const Text(AppStrings.grantPermission),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.accent,
                  foregroundColor: context.palette.onAccent,
                ),
              ),
            ],
          ),
        ),
      );
}

class _NeedleGauge extends StatelessWidget {
  const _NeedleGauge({required this.cents, required this.color});

  final double? cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = cents == null ? 0.0 : (cents! / 50.0).clamp(-1.0, 1.0);
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: fraction,
          color: color,
          palette: context.palette,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.color,
    required this.palette,
  });

  final double fraction;
  final AppPalette palette;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.42;

    // Arc track
    final trackPaint = Paint()
      ..color = palette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Center tick
    final tickPaint = Paint()
      ..color = palette.textDisabled
      ..strokeWidth = 2;
    canvas.drawLine(
      center - Offset(0, radius - 10),
      center - Offset(0, radius + 10),
      tickPaint,
    );

    // Needle
    final angle = math.pi + (fraction + 1) / 2 * math.pi;
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final tip = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawLine(center, tip, needlePaint);

    // Pivot dot
    canvas.drawCircle(center, 8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.palette != palette;
}

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({required this.state});

  final TunerState state;

  @override
  Widget build(BuildContext context) {
    final centsLabel = state.cents == null
        ? ''
        : '${state.cents!.toStringAsFixed(1)} ${AppStrings.cents}';
    final freqLabel = state.frequency == null
        ? ''
        : '${state.frequency!.toStringAsFixed(2)} Hz';
    final statusLabel = state.isInTune
        ? AppStrings.inTune
        : (state.cents ?? 0) > 0
            ? AppStrings.sharp
            : AppStrings.flat;

    return Column(
      children: [
        Text(
          state.note ?? '—',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 64,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.note == null ? AppStrings.tunerIdle : statusLabel,
          style: TextStyle(
            color: state.isInTune
                ? context.palette.success
                : context.palette.textSecondary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          freqLabel,
          style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
        ),
        Text(
          centsLabel,
          style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _ReferenceChips extends StatelessWidget {
  const _ReferenceChips({required this.current, required this.onSelect});

  final double current;
  final void Function(double) onSelect;

  static const _options = [432.0, 440.0, 442.0, 444.0];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference Pitch',
            style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _options.map((hz) {
              final selected = hz == current;
              return ChoiceChip(
                label: Text('${hz.toInt()} Hz'),
                selected: selected,
                onSelected: (_) => onSelect(hz),
                selectedColor: context.palette.accent,
                labelStyle: TextStyle(
                  color: selected ? context.palette.onAccent : context.palette.textPrimary,
                ),
                backgroundColor: context.palette.surface,
              );
            }).toList(),
          ),
        ],
      );
}

class _GuitarStringsRow extends StatelessWidget {
  const _GuitarStringsRow();

  static const _strings = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Standard Tuning Reference',
            style: TextStyle(color: context.palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _strings
                .map((s) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.palette.surface,
                        border: Border.all(color: context.palette.accent, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s,
                        style: TextStyle(
                          color: context.palette.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      );
}
