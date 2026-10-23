# 🍇 Vinogradar Teleprompter - Flutter verzija

Ovo je Flutter verzija Android aplikacije, koja radi na **iOS i Android**.

---

## 📱 Kako instalirati na iPhone (bez MacBooka, bez developer accounta)

### Opcija A: AltStore (preporučeno, besplatno)

1. **Na računaru (Windows ili Mac)** instaliraj [AltServer](https://altstore.io)
2. Povedi iPhone na isti WiFi kao računar
3. AltServer → "Install AltStore" → odaberi iPhone
4. Na iPhone: Postavke → Privatnost → Upravljanje uređajima → pouzdaj Apple ID-u
5. AltStore na iPhoneu → "+" → odaberi `.ipa` fajl
6. Aplikacija radi 7 dana, AltStore je automatski obnavlja dok si na istom WiFi-u

### Opcija B: Sideloadly (jednostavniji)

1. Instaliraj [Sideloadly](https://sideloadly.io) na Windows
2. Poveži iPhone USB-om
3. Prevuci `.ipa` fajl u Sideloadly, unesi Apple ID, klikni Start
4. Na iPhoneu: Postavke → Upravljanje uređajima → pouzdaj

---

## 🛠️ Kako kompajlirati (ako imaš prijatelja s Macom)

```bash
# 1. Instaliraj Flutter: https://docs.flutter.dev/get-started/install/macos
# 2. Kloniraj / kopiraš ovaj folder
cd vinogradar_teleprompter

# 3. Instaliraj dependencies
flutter pub get

# 4. Poveži iPhone i pokrni
flutter run

# 5. Ili napravi .ipa za distribuciju
flutter build ipa --no-codesign
```

---

## 📂 Struktura projekta

```
lib/
├── main.dart              # Entry point i navigacija
├── data/
│   ├── models.dart        # Script, CalibrationProfile
│   ├── repository.dart    # Čuvanje podataka (SharedPreferences)
│   └── app_state.dart     # State management (ChangeNotifier)
├── theme/
│   └── app_theme.dart     # Dark/light tema, boje
└── screens/
    ├── library_screen.dart    # Biblioteka skripti
    ├── editor_screen.dart     # Uređivač teksta
    ├── prompter_screen.dart   # Teleprompter + kamera
    └── calibration_screen.dart # Kalibracija WPM/fonta
```

---

## ✅ Funkcije

| Funkcija | Android | Flutter (iOS+Android) |
|---------|---------|----------------------|
| Biblioteka skripti | ✅ | ✅ |
| Editor s naglascima (*zvjezdice*) | ✅ | ✅ |
| Teleprompter scroll | ✅ | ✅ |
| Kamera preview | ✅ | ✅ |
| Grid (pravilo trećine) | ✅ | ✅ |
| Ogledalo tekst | ✅ | ✅ |
| Kalibracija WPM | ✅ | ✅ |
| Dark/light tema | ✅ | ✅ |
| Uvoz .docx/.txt | ✅ | ⚠️ (dodati file_picker) |
| Glasovne komande | ✅ | ⚠️ (iOS ograničenje) |
| Video snimanje | ✅ | ⚠️ (dodati video_player) |

---

## 🔧 Potrebni paketi

```yaml
dependencies:
  shared_preferences: ^2.2.2   # Čuvanje skripti
  uuid: ^4.3.3                 # Jedinstveni ID-ovi
  camera: ^0.11.0+2            # Kamera
  permission_handler: ^11.3.0  # Dozvole (kamera, mikrofon)
  archive: ^3.4.9              # .docx parser
  provider: ^6.1.2             # State management
```

---

## 💡 Savjeti

- Tekst s `*zvjezdicama*` postaje **zlatni** u prompteru
- Povlačenje gore/dolje mijenja brzinu scrollanja
- Kalibracija pamti tvoj tempo govora i automatski podešava brzinu
