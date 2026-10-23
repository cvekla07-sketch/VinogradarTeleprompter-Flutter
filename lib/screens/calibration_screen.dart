import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/models.dart';

const _testScript =
    'Dobar dan dragi prijatelji vinogradari! Danas vam predstavljam jednu zaista važnu temu u svijetu vinogradarstva. Pričaćemo o pravilnom održavanju vinove loze tokom cijele godine. Svaki vinogradar zna da samo predan rad daje najbolje rezultate u našem prelijepom vinogradu. Hvala vam što me pratite i čitate ovaj tekst pažljivo.';

class CalibrationScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const CalibrationScreen({super.key, required this.onFinish});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _step = 0;
  int _measuredWpm = 0;
  int _selectedFontSize = 56;
  double _calculatedSpeed = 3.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onFinish,
        ),
        title: Text('Kalibracija ${_step + 1}/3'),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= _step ? cs.primary : cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _WpmStep(
          key: const ValueKey(0),
          onNext: (wpm) {
            setState(() {
              _measuredWpm = wpm;
              _calculatedSpeed = (wpm / 50.0).clamp(0.5, 10.0);
              _step = 1;
            });
          },
        );
      case 1:
        return _FontStep(
          key: const ValueKey(1),
          initialSize: _selectedFontSize,
          onNext: (size) => setState(() { _selectedFontSize = size; _step = 2; }),
          onBack: () => setState(() => _step = 0),
        );
      case 2:
        return _ResultsStep(
          key: const ValueKey(2),
          wpm: _measuredWpm,
          fontSize: _selectedFontSize,
          speed: _calculatedSpeed,
          onSave: () {
            context.read<AppState>().saveCalibration(CalibrationProfile(
              wpm: _measuredWpm,
              recommendedFontSize: _selectedFontSize,
              recommendedSpeed: _calculatedSpeed,
              calibratedAt: DateTime.now().millisecondsSinceEpoch,
              isCalibrated: true,
            ));
            widget.onFinish();
          },
          onBack: () => setState(() => _step = 1),
          onRestart: () => setState(() { _measuredWpm = 0; _step = 0; }),
        );
      default:
        return const SizedBox();
    }
  }
}

class _WpmStep extends StatefulWidget {
  final Function(int) onNext;
  const _WpmStep({super.key, required this.onNext});

  @override
  State<_WpmStep> createState() => _WpmStepState();
}

class _WpmStepState extends State<_WpmStep> {
  bool _isReading = false;
  bool _isFinished = false;
  int _elapsed = 0;
  Timer? _timer;

  final int _wordCount = _testScript.trim().split(RegExp(r'\s+')).length;

  int get _wpm => _elapsed > 0 ? (_wordCount * 60 ~/ _elapsed) : 0;

  void _start() {
    setState(() { _isReading = true; _elapsed = 0; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() { _isReading = false; _isFinished = true; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.speed, color: cs.primary, size: 56),
          const SizedBox(height: 12),
          const Text('Korak 1: Brzina govora',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Mjeriće se koliko brzo prirodno govoriš.',
              style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (!_isReading && !_isFinished) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📖 Pročitaj naglas tekst ispod prirodnim tempom. Ne ubrzavaj niti usporavaj.',
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_testScript,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('ZAPOČNI ČITANJE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              ),
            ),
          ] else if (_isReading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text('⏱ ČITAM...', style: TextStyle(color: cs.onPrimaryContainer)),
                const SizedBox(height: 8),
                Text(_formatTimer(_elapsed),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: cs.primary)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_testScript,
                  style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                label: const Text('GOTOV SAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: cs.tertiary),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text('✓ MJERENJE GOTOVO', style: TextStyle(color: cs.primary, fontSize: 12)),
                const SizedBox(height: 12),
                Text('$_wpm', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: cs.primary)),
                const Text('RIJEČI U MINUTI', style: TextStyle(fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text('Tvoj stil: ${_wpmDesc(_wpm)}',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 20),
            if (_wpm < 50 || _wpm > 250) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
                child: Text('⚠️ Rezultat djeluje nerealno. Pokušaj ponovo.',
                    style: TextStyle(color: cs.onErrorContainer)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() { _isFinished = false; _elapsed = 0; }),
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ] else Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _isFinished = false; _elapsed = 0; }),
                  child: const Text('Ponovi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.onNext(_wpm),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                  child: const Text('Dalje', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _FontStep extends StatefulWidget {
  final int initialSize;
  final Function(int) onNext;
  final VoidCallback onBack;
  const _FontStep({super.key, required this.initialSize, required this.onNext, required this.onBack});

  @override
  State<_FontStep> createState() => _FontStepState();
}

class _FontStepState extends State<_FontStep> {
  late int _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.text_fields, color: cs.primary, size: 56),
          const SizedBox(height: 12),
          const Text('Korak 2: Veličina fonta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Postavi telefon na udaljenost snimanja. Mijenjaj dok ne vidiš jasno.',
              style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ovo je test rečenica. Provjeri da li ti je tekst jasan i čitljiv sa udaljenosti odakle ćeš snimati.',
                    style: TextStyle(color: Colors.white, fontSize: _fontSize.toDouble(),
                        height: 1.4, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                Text('Aa', style: TextStyle(color: cs.onSurfaceVariant)),
                Expanded(
                  child: Slider(
                    value: _fontSize.toDouble(), min: 28, max: 100,
                    onChanged: (v) => setState(() => _fontSize = v.toInt()),
                    activeColor: cs.primary, inactiveColor: cs.surface,
                  ),
                ),
                Text('${_fontSize}sp', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _PresetChip('Blizu', 40, _fontSize, (v) => setState(() => _fontSize = v)),
                _PresetChip('Stativ', 60, _fontSize, (v) => setState(() => _fontSize = v)),
                _PresetChip('Dalje', 80, _fontSize, (v) => setState(() => _fontSize = v)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Nazad'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => widget.onNext(_fontSize),
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                child: const Text('Dalje', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final int size;
  final int currentSize;
  final Function(int) onTap;
  const _PresetChip(this.label, this.size, this.currentSize, this.onTap);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = currentSize == size;
    return GestureDetector(
      onTap: () => onTap(size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? cs.primary : cs.outline),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: active ? cs.onPrimary : cs.onSurface)),
          Text('${size}sp', style: TextStyle(
              fontSize: 9, color: active ? cs.onPrimary.withOpacity(0.7) : cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _ResultsStep extends StatelessWidget {
  final int wpm, fontSize;
  final double speed;
  final VoidCallback onSave, onBack, onRestart;

  const _ResultsStep({
    super.key, required this.wpm, required this.fontSize, required this.speed,
    required this.onSave, required this.onBack, required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: cs.primary, size: 64),
          const SizedBox(height: 12),
          const Text('Kalibracija završena!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tvoji rezultati biće sačuvani i automatski primijenjeni.',
              style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _ResultCard(Icons.speed, 'BRZINA GOVORA', '$wpm WPM', _wpmDesc(wpm)),
          const SizedBox(height: 12),
          _ResultCard(Icons.text_fields, 'VELIČINA FONTA', '${fontSize}sp', _fontDesc(fontSize)),
          const SizedBox(height: 12),
          _ResultCard(Icons.play_circle, 'BRZINA PROMPTER-A',
              '${speed.toStringAsFixed(1)}x', 'Automatski izračunato iz WPM'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('SAČUVAJ KALIBRACIJU',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: onBack, child: const Text('Promijeni'))),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(onPressed: onRestart, child: const Text('Ispočetka'))),
          ]),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label, value, desc;
  const _ResultCard(this.icon, this.label, this.value, this.desc);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.15),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1, color: cs.onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
          Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}

String _formatTimer(int s) => '${(s ~/ 60)}:${(s % 60).toString().padLeft(2, '0')}';
String _wpmDesc(int wpm) {
  if (wpm < 110) return 'Vrlo spor (smiren)';
  if (wpm < 130) return 'Spor — odlično za edukaciju';
  if (wpm < 150) return 'Prosječan tempo';
  if (wpm < 170) return 'Brz — energičan stil';
  return 'Vrlo brz';
}
String _fontDesc(int size) {
  if (size < 40) return 'Za bliske snimke (selfie)';
  if (size < 60) return 'Standardno (telefon u ruci)';
  if (size < 80) return 'Za stativ na 1m';
  return 'Za dalje udaljenosti';
}
