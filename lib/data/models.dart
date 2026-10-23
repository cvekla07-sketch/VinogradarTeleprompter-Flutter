import 'dart:convert';

class Script {
  final String id;
  final String title;
  final String content;
  final int createdAt;
  final int updatedAt;

  Script({
    String? id,
    this.title = '',
    this.content = '',
    int? createdAt,
    int? updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int get estimatedDurationSec => (wordCount * 60.0 / 150.0).toInt();

  Script copyWith({
    String? id,
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
  }) {
    return Script(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Script.fromJson(Map<String, dynamic> json) => Script(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as int?,
        updatedAt: json['updatedAt'] as int?,
      );
}

class CalibrationProfile {
  final int wpm;
  final int recommendedFontSize;
  final double recommendedSpeed;
  final int calibratedAt;
  final bool isCalibrated;

  const CalibrationProfile({
    this.wpm = 0,
    this.recommendedFontSize = 56,
    this.recommendedSpeed = 3.0,
    this.calibratedAt = 0,
    this.isCalibrated = false,
  });

  String get calibratedDate {
    if (calibratedAt == 0) return 'Nikada';
    final dt = DateTime.fromMillisecondsSinceEpoch(calibratedAt);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String get wpmDescription {
    if (wpm == 0) return 'Nepoznato';
    if (wpm < 110) return 'Vrlo spor';
    if (wpm < 130) return 'Spor (smiren)';
    if (wpm < 150) return 'Prosječan';
    if (wpm < 170) return 'Brz';
    return 'Vrlo brz';
  }

  CalibrationProfile copyWith({
    int? wpm,
    int? recommendedFontSize,
    double? recommendedSpeed,
    int? calibratedAt,
    bool? isCalibrated,
  }) =>
      CalibrationProfile(
        wpm: wpm ?? this.wpm,
        recommendedFontSize: recommendedFontSize ?? this.recommendedFontSize,
        recommendedSpeed: recommendedSpeed ?? this.recommendedSpeed,
        calibratedAt: calibratedAt ?? this.calibratedAt,
        isCalibrated: isCalibrated ?? this.isCalibrated,
      );

  Map<String, dynamic> toJson() => {
        'wpm': wpm,
        'recommendedFontSize': recommendedFontSize,
        'recommendedSpeed': recommendedSpeed,
        'calibratedAt': calibratedAt,
        'isCalibrated': isCalibrated,
      };

  factory CalibrationProfile.fromJson(Map<String, dynamic> json) =>
      CalibrationProfile(
        wpm: json['wpm'] as int? ?? 0,
        recommendedFontSize: json['recommendedFontSize'] as int? ?? 56,
        recommendedSpeed: (json['recommendedSpeed'] as num?)?.toDouble() ?? 3.0,
        calibratedAt: json['calibratedAt'] as int? ?? 0,
        isCalibrated: json['isCalibrated'] as bool? ?? false,
      );
}
