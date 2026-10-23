import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_state.dart';
import 'data/models.dart';
import 'theme/app_theme.dart';
import 'screens/library_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/prompter_screen.dart';
import 'screens/calibration_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VinogradarApp(),
    ),
  );
}

class VinogradarApp extends StatelessWidget {
  const VinogradarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkTheme;
    return MaterialApp(
      title: 'Vinogradar Teleprompter',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _AppNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum _Screen { library, editor, prompter, calibration }

class _AppNavigator extends StatefulWidget {
  const _AppNavigator();

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  _Screen _screen = _Screen.library;

  void _go(_Screen screen) => setState(() => _screen = screen);

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    switch (_screen) {
      case _Screen.library:
        return LibraryScreen(
          onNewScript: () async {
            await state.newScript();
            _go(_Screen.editor);
          },
          onScriptOpen: (script) {
            state.selectScript(script);
            _go(_Screen.editor);
          },
          onOpenCalibration: () => _go(_Screen.calibration),
        );
      case _Screen.editor:
        return EditorScreen(
          onBack: () => _go(_Screen.library),
          onStartPrompter: () => _go(_Screen.prompter),
        );
      case _Screen.prompter:
        return PrompterScreen(
          onExit: () => _go(_Screen.editor),
        );
      case _Screen.calibration:
        return CalibrationScreen(
          onFinish: () => _go(_Screen.library),
        );
    }
  }
}
