import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';

class PrompterScreen extends StatefulWidget {
  final VoidCallback onExit;
  const PrompterScreen({super.key, required this.onExit});

  @override
  State<PrompterScreen> createState() => _PrompterScreenState();
}

class _PrompterScreenState extends State<PrompterScreen> {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _hasCameraPerm = false;
  bool _hasMicPerm = false;
  bool _permChecked = false;
  int _camIndex = 1; // front camera

  bool _isPlaying = false;
  bool _isMirroredLocal = false;
  bool _showGrid = true;
  int _elapsedSeconds = 0;

  final ScrollController _scrollCtrl = ScrollController();
  Timer? _scrollTimer;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (cam.isGranted && mic.isGranted) {
      setState(() {
        _hasCameraPerm = true;
        _hasMicPerm = true;
        _permChecked = true;
      });
      await _initCamera();
    } else {
      final results = await [Permission.camera, Permission.microphone].request();
      setState(() {
        _hasCameraPerm = results[Permission.camera]?.isGranted ?? false;
        _hasMicPerm = results[Permission.microphone]?.isGranted ?? false;
        _permChecked = true;
      });
      if (_hasCameraPerm) await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final idx = _camIndex < _cameras.length ? _camIndex : 0;
      final ctrl = CameraController(
        _cameras[idx],
        ResolutionPreset.high,
        enableAudio: _hasMicPerm,
      );
      await ctrl.initialize();
      if (mounted) setState(() => _cameraCtrl = ctrl);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    await _cameraCtrl?.dispose();
    _cameraCtrl = null;
    _camIndex = (_camIndex + 1) % (_cameras.isEmpty ? 2 : _cameras.length);
    await _initCamera();
  }

  void _togglePlay(double speed) {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startScrolling(speed);
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    } else {
      _stopScrolling();
    }
  }

  void _startScrolling(double speed) {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollCtrl.hasClients) return;
      final next = _scrollCtrl.offset + speed.clamp(0.5, 10);
      if (next >= _scrollCtrl.position.maxScrollExtent) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        setState(() => _isPlaying = false);
        _stopScrolling();
      } else {
        _scrollCtrl.jumpTo(next);
      }
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _elapsedTimer?.cancel();
  }

  void _reset() {
    setState(() {
      _isPlaying = false;
      _elapsedSeconds = 0;
    });
    _stopScrolling();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _elapsedTimer?.cancel();
    _cameraCtrl?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasCameraPerm || !_hasMicPerm) {
      return _PermissionScreen(
        hasCam: _hasCameraPerm,
        hasMic: _hasMicPerm,
        onRetry: _checkPermissions,
        onExit: widget.onExit,
      );
    }

    final state = context.watch<AppState>();
    final script = state.currentScript;
    final content = script?.content ?? '';
    final fontSize = state.fontSize.toDouble();
    final scrollSpeed = state.scrollSpeed;
    final isMirrored = state.isMirrored;

    return WillPopScope(
      onWillPop: () async {
        widget.onExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // CAMERA
            if (_cameraCtrl != null && _cameraCtrl!.value.isInitialized)
              SizedBox.expand(
                child: CameraPreview(_cameraCtrl!),
              )
            else
              Container(color: Colors.black),

            // GRID
            if (_showGrid) _GridOverlay(),

            // Dark overlay
            Container(color: Colors.black.withOpacity(0.45)),

            // TEXT
            GestureDetector(
              onVerticalDragUpdate: (d) {
                final newSpeed = (scrollSpeed - d.delta.dy / 100).clamp(0.5, 10.0);
                state.setScrollSpeed(newSpeed);
                if (_isPlaying) {
                  _startScrolling(newSpeed);
                }
              },
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 300),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Transform.scale(
                        scaleX: isMirrored ? -1 : 1,
                        child: Text.rich(
                          _parseHighlights(content),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),

            // Reading guide line
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    gold.withOpacity(0.6),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // Fade top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xE6000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Fade bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF2000000)],
                  ),
                ),
              ),
            ),

            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimerBadge(seconds: _elapsedSeconds),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_on,
                              color: _showGrid ? gold : Colors.white),
                          onPressed: () => setState(() => _showGrid = !_showGrid),
                          style: IconButton.styleFrom(
                            backgroundColor: _showGrid
                                ? gold.withOpacity(0.3)
                                : Colors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${scrollSpeed.toStringAsFixed(1)}x',
                            style: const TextStyle(
                                color: gold, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Speed slider
                      Row(
                        children: [
                          const Text('Brzina',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                thumbColor: gold,
                                activeTrackColor: gold,
                                inactiveTrackColor: Colors.white24,
                              ),
                              child: Slider(
                                value: scrollSpeed,
                                min: 0.5,
                                max: 10,
                                onChanged: (v) {
                                  state.setScrollSpeed(v);
                                  if (_isPlaying) _startScrolling(v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CtrlButton(
                            icon: Icons.close,
                            label: 'IZLAZ',
                            onTap: widget.onExit,
                          ),
                          _CtrlButton(
                            icon: Icons.cameraswitch,
                            label: 'KAMERA',
                            onTap: _switchCamera,
                          ),
                          _CtrlButton(
                            icon: Icons.replay,
                            label: 'RESET',
                            onTap: _reset,
                          ),
                          // Play/Pause big button
                          GestureDetector(
                            onTap: () => _togglePlay(scrollSpeed),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isPlaying ? danger : gold,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                          ),
                          _CtrlButton(
                            icon: Icons.flip,
                            label: isMirrored ? 'OGLEDALO ✓' : 'OGLEDALO',
                            active: isMirrored,
                            onTap: () => state.toggleMirror(),
                          ),
                          _CtrlButton(
                            icon: Icons.mic_off,
                            label: 'GLAS',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Glasovna kontrola dostupna u Android verziji'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 5;
    final goldPaint = Paint()
      ..color = gold
      ..strokeWidth = 4;

    // Vertical lines
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), shadowPaint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), shadowPaint);
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), whitePaint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), whitePaint);

    // Bottom horizontal line
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), shadowPaint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), whitePaint);

    // Eye line (gold)
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3),
        Paint()..color = Colors.black.withOpacity(0.7)..strokeWidth = 8);
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), goldPaint);

    // Dots on top intersections
    final dotPaint = Paint()..color = gold;
    canvas.drawCircle(Offset(w / 3, h / 3), 12, dotPaint);
    canvas.drawCircle(Offset(2 * w / 3, h / 3), 12, dotPaint);
    canvas.drawCircle(Offset(w / 3, h / 3), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(2 * w / 3, h / 3), 5, Paint()..color = Colors.white);

    // Bottom dots (white, smaller)
    final whiteDot = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(Offset(w / 3, 2 * h / 3), 7, whiteDot);
    canvas.drawCircle(Offset(2 * w / 3, 2 * h / 3), 7, whiteDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimerBadge extends StatelessWidget {
  final int seconds;
  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = gold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? activeColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon,
                color: active ? activeColor : Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: active ? activeColor : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _PermissionScreen extends StatelessWidget {
  final bool hasCam;
  final bool hasMic;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _PermissionScreen({
    required this.hasCam,
    required this.hasMic,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Potrebne dozvole',
                  style: TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _PermRow('Kamera (za snimanje)', hasCam),
              const SizedBox(height: 8),
              _PermRow('Mikrofon (za zvuk)', hasMic),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(backgroundColor: gold),
                  child: const Text('DOZVOLI',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onExit,
                child: const Text('Nazad', style: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String label;
  final bool granted;
  const _PermRow(this.label, this.granted);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(granted ? Icons.check_circle : Icons.cancel,
            color: granted ? gold : danger),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}

TextSpan _parseHighlights(String text) {
  final children = <TextSpan>[];
  final regex = RegExp(r'\*([^*]+)\*');
  int lastIndex = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > lastIndex) {
      children.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }
    children.add(TextSpan(
      text: match.group(1),
      style: const TextStyle(
          color: gold, fontWeight: FontWeight.bold),
    ));
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    children.add(TextSpan(text: text.substring(lastIndex)));
  }
  return TextSpan(children: children);
}
