import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ScriptRepository {
  static const _scriptsKey = 'scripts_json';
  static const _calibrationKey = 'calibration_json';

  Future<List<Script>> loadScripts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scriptsKey);
    if (raw == null) return _defaultScripts();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Script.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultScripts();
    }
  }

  Future<void> saveScripts(List<Script> scripts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scriptsKey, jsonEncode(scripts.map((s) => s.toJson()).toList()));
  }

  Future<CalibrationProfile> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calibrationKey);
    if (raw == null) return const CalibrationProfile();
    try {
      return CalibrationProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CalibrationProfile();
    }
  }

  Future<void> saveCalibration(CalibrationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calibrationKey, jsonEncode(profile.toJson()));
  }

  List<Script> _defaultScripts() => [
        Script(
          title: 'Primjer: Rezidba u proljeće',
          content: '''Dobar dan dragim vinogradarima!

Danas ćemo govoriti o jednoj od *najvažnijih* aktivnosti u vinogradu — proljetnoj rezidbi loze.

Rezidba se obavlja u periodu *mirovanja* loze, obično od kraja februara do početka aprila, zavisno od klimatskih uslova vašeg područja.

Tri ključna pravila koja morate zapamtiti:

Prvo — uvijek koristite *oštre i dezinfikovane* alate. Tupe makaze prave rane koje se sporo zarastaju i pozivaju bolesti.

Drugo — režite *iznad pupa*, oko jedan centimetar, pod blagim uglom. Ovo omogućava da voda otiče dalje od pupa.

Treće — uklonite sve *slabe i bolesne mladare*. Zdrava loza je produktivna loza.''',
        ),
        Script(
          title: 'Primjer: Zaštita od peronospore',
          content: '''Pozdrav prijatelji vinogradari!

Peronospora je *najopasnija* bolest vinove loze u našim krajevima. Danas ćemo naučiti kako je *prepoznati* i *spriječiti*.

Prvi znaci pojavljuju se na listovima — *uljaste mrlje* svijetlo žute boje. Ako okrenete list, na donjoj strani vidjet ćete *bijelu navlaku*.

Preventiva je *ključ uspjeha*. Prskanje počinjemo kada mladari dostignu deset centimetara visine.''',
        ),
      ];
}
