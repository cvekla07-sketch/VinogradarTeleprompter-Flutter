import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';

class AppState extends ChangeNotifier {
  final ScriptRepository _repo = ScriptRepository();

  List<Script> _scripts = [];
  Script? _currentScript;
  int _fontSize = 56;
  double _scrollSpeed = 3.0;
  bool _isMirrored = false;
  bool _isDarkTheme = true;
  CalibrationProfile _calibration = const CalibrationProfile();

  List<Script> get scripts => _scripts;
  Script? get currentScript => _currentScript;
  int get fontSize => _fontSize;
  double get scrollSpeed => _scrollSpeed;
  bool get isMirrored => _isMirrored;
  bool get isDarkTheme => _isDarkTheme;
  CalibrationProfile get calibration => _calibration;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _scripts = await _repo.loadScripts();
    _calibration = await _repo.loadCalibration();
    if (_calibration.isCalibrated) {
      _fontSize = _calibration.recommendedFontSize;
      _scrollSpeed = _calibration.recommendedSpeed;
    }
    notifyListeners();
  }

  void selectScript(Script script) {
    _currentScript = script;
    notifyListeners();
  }

  Future<void> newScript() async {
    final fresh = Script(title: 'Nova skripta', content: '');
    _scripts = [..._scripts, fresh];
    _currentScript = fresh;
    await _repo.saveScripts(_scripts);
    notifyListeners();
  }

  Future<void> importScript(Script script) async {
    final exists = _scripts.any((s) => s.title == script.title);
    final finalTitle = exists
        ? '${script.title} (${_nowFormatted()})'
        : script.title;
    final finalScript = script.copyWith(title: finalTitle);
    _scripts = [..._scripts, finalScript];
    _currentScript = finalScript;
    await _repo.saveScripts(_scripts);
    notifyListeners();
  }

  Future<void> updateScript(Script updated) async {
    final updatedWithTime = updated.copyWith();
    _currentScript = updatedWithTime;
    final list = List<Script>.from(_scripts);
    final idx = list.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      list[idx] = updatedWithTime;
    } else {
      list.add(updatedWithTime);
    }
    _scripts = list;
    await _repo.saveScripts(_scripts);
    notifyListeners();
  }

  Future<void> deleteScript(Script script) async {
    _scripts = _scripts.where((s) => s.id != script.id).toList();
    if (_currentScript?.id == script.id) _currentScript = null;
    await _repo.saveScripts(_scripts);
    notifyListeners();
  }

  void setFontSize(int size) {
    _fontSize = size;
    notifyListeners();
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
    notifyListeners();
  }

  void toggleMirror() {
    _isMirrored = !_isMirrored;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  Future<void> saveCalibration(CalibrationProfile profile) async {
    _calibration = profile;
    _fontSize = profile.recommendedFontSize;
    _scrollSpeed = profile.recommendedSpeed;
    await _repo.saveCalibration(profile);
    notifyListeners();
  }

  String _nowFormatted() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
