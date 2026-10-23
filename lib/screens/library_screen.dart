import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onNewScript;
  final Function(Script) onScriptOpen;
  final VoidCallback onOpenCalibration;

  const LibraryScreen({
    super.key,
    required this.onNewScript,
    required this.onScriptOpen,
    required this.onOpenCalibration,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Script? _scriptToDelete;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [wineRed, goldDark]),
              ),
              child: const Center(child: Text('🍇', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vinogradar', style: Theme.of(context).textTheme.titleLarge),
                Text('TELEPROMPTER PRO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          letterSpacing: 1,
                        )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(state.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => state.toggleTheme(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNewScript,
        icon: const Icon(Icons.add),
        label: const Text('Nova skripta', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalibrationCard(
            calibration: state.calibration,
            onTap: widget.onOpenCalibration,
          ),
          const SizedBox(height: 12),
          if (state.scripts.isEmpty)
            _EmptyState()
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Text('MOJE SKRIPTE',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1)),
            ),
            ...state.scripts.map((script) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScriptCard(
                    script: script,
                    onTap: () => widget.onScriptOpen(script),
                    onDelete: () => setState(() => _scriptToDelete = script),
                  ),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  final CalibrationProfile calibration;
  final VoidCallback onTap;

  const _CalibrationCard({required this.calibration, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCalibrated = calibration.isCalibrated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.4), width: 1.5),
          gradient: LinearGradient(
            colors: isCalibrated
                ? [cs.primary.withOpacity(0.15), cs.tertiary.withOpacity(0.15)]
                : [cs.secondaryContainer, cs.primaryContainer],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cs.primary,
                    child: Icon(Icons.settings, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCalibrated ? 'Kalibracija aktivna ✓' : '🎯 Kalibracija',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isCalibrated
                              ? 'Postavke prilagođene tvom stilu'
                              : 'Personalizuj prompter za savršene snimke',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_arrow, color: cs.primary),
                ],
              ),
            ),
            if (isCalibrated)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CalibStat('${calibration.wpm}', 'WPM'),
                    _CalibStat('${calibration.recommendedFontSize}sp', 'FONT'),
                    _CalibStat(calibration.recommendedSpeed.toStringAsFixed(1) + 'x', 'BRZINA'),
                    _CalibStat(calibration.calibratedDate, 'DATUM'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalibStat extends StatelessWidget {
  final String value;
  final String label;
  const _CalibStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
        Text(label,
            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant, letterSpacing: 1)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Text('🍇', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text('Nema skripti', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Kreiraj prvu skriptu klikom na dugme dole',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ScriptCard extends StatelessWidget {
  final Script script;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScriptCard({required this.script, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    script.title.isEmpty ? 'Bez naslova' : script.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatChip('${script.wordCount} riječi'),
                      const SizedBox(width: 8),
                      _StatChip(_formatDuration(script.estimatedDurationSec)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: cs.primary, size: 28),
              onPressed: onTap,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: cs.onSurfaceVariant),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String text;
  const _StatChip(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500)),
    );
  }
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')} min';
}
