import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';

class EditorScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onStartPrompter;

  const EditorScreen({super.key, required this.onBack, required this.onStartPrompter});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save(AppState state) {
    final script = state.currentScript;
    if (script == null) return;
    final updated = script.copyWith(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
    );
    state.updateScript(updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final script = state.currentScript;
    final cs = Theme.of(context).colorScheme;

    if (!_initialized && script != null) {
      _titleCtrl = TextEditingController(text: script.title);
      _contentCtrl = TextEditingController(text: script.content);
      _titleCtrl.addListener(() => _save(state));
      _contentCtrl.addListener(() => _save(state));
      _initialized = true;
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final wordCount = _contentCtrl.text.trim().isEmpty
        ? 0
        : _contentCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final durationSec = (wordCount * 60.0 / 150.0).toInt();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Naslov skripte...',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontSize: 17, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Upiši svoju skriptu ovdje...\n\n💡 Savjet: koristi *zvjezdice* oko riječi za naglasak — postaće zlatne u prompteru.\n\nPrimjer:\n"Dobar dan dragi vinogradari! Danas govorimo o *rezidbi* loze..."',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          _BottomBar(
            wordCount: wordCount,
            durationSec: durationSec,
            fontSize: state.fontSize,
            scrollSpeed: state.scrollSpeed,
            onStartPrompter: widget.onStartPrompter,
            contentNotEmpty: _contentCtrl.text.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int wordCount;
  final int durationSec;
  final int fontSize;
  final double scrollSpeed;
  final VoidCallback onStartPrompter;
  final bool contentNotEmpty;

  const _BottomBar({
    required this.wordCount,
    required this.durationSec,
    required this.fontSize,
    required this.scrollSpeed,
    required this.onStartPrompter,
    required this.contentNotEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBlock('$wordCount', 'RIJEČI'),
                _StatBlock(_formatTime(durationSec), 'PROCJENA'),
                _StatBlock('${fontSize}sp', 'FONT'),
                _StatBlock('${scrollSpeed.toStringAsFixed(1)}x', 'BRZINA'),
              ],
            ),
            const SizedBox(height: 8),
            // Font size slider
            Row(
              children: [
                Text('Aa', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: state.fontSize.toDouble(),
                    min: 28,
                    max: 100,
                    onChanged: (v) => state.setFontSize(v.toInt()),
                    activeColor: cs.primary,
                    inactiveColor: cs.surfaceVariant,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text('${state.fontSize}sp',
                      style: TextStyle(
                          fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
            // Speed slider
            Row(
              children: [
                Text('⏱', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: state.scrollSpeed,
                    min: 0.5,
                    max: 10,
                    onChanged: (v) => state.setScrollSpeed(v),
                    activeColor: cs.primary,
                    inactiveColor: cs.surfaceVariant,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text('${state.scrollSpeed.toStringAsFixed(1)}x',
                      style: TextStyle(
                          fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: contentNotEmpty ? onStartPrompter : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('POKRENI PROMPTER',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: cs.onSurfaceVariant, letterSpacing: 1)),
      ],
    );
  }
}

String _formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
