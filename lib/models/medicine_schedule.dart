import 'dart:math' as math;

class MedicineSchedule {
  final String id;
  final String name;
  final int dose;
  final int remainingStock;
  final String mealRule;
  final String time;
  final String type;
  final int medicineBox;
  final int notificationId;
  final String? lastStockUpdateDate;

  const MedicineSchedule({
    required this.id,
    required this.name,
    required this.dose,
    required this.remainingStock,
    required this.mealRule,
    required this.time,
    required this.type,
    required this.medicineBox,
    required this.notificationId,
    this.lastStockUpdateDate,
  });

  factory MedicineSchedule.create({
    required String name,
    required int dose,
    required int remainingStock,
    required String mealRule,
    required String time,
    required String type,
    required int medicineBox,
    required int notificationId,
    String? lastStockUpdateDate,
  }) {
    return MedicineSchedule(
      id: _generateId(),
      name: name,
      dose: dose,
      remainingStock: remainingStock,
      mealRule: mealRule,
      time: time,
      type: type,
      medicineBox: medicineBox,
      notificationId: notificationId,
      lastStockUpdateDate: lastStockUpdateDate,
    );
  }

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    final int parsedDose =
        _parsePositiveInt(json['dose']) ??
        _parsePositiveInt(json['dosage']) ??
        1;

    return MedicineSchedule(
      id: json['id']?.toString() ?? _generateId(),
      name: json['name']?.toString() ?? '',
      dose: parsedDose,
      remainingStock: _parsePositiveInt(json['remainingStock']) ?? parsedDose,
      mealRule:
          json['mealRule']?.toString() ??
          _extractMealRule(json['dosage']?.toString()) ??
          'Sesudah Makan',
      time: json['time']?.toString() ?? '',
      type: _normalizeType(json['type']),
      medicineBox: _parseMedicineBox(json['medicineBox']),
      notificationId:
          _parsePositiveInt(json['notificationId']) ??
          math.Random().nextInt(100000),
      lastStockUpdateDate: _parseNullableText(json['lastStockUpdateDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'remainingStock': remainingStock,
      'mealRule': mealRule,
      'time': time,
      'type': type,
      'medicineBox': medicineBox,
      'notificationId': notificationId,
      'lastStockUpdateDate': lastStockUpdateDate,
    };
  }

  MedicineSchedule copyWith({
    String? id,
    String? name,
    int? dose,
    int? remainingStock,
    String? mealRule,
    String? time,
    String? type,
    int? medicineBox,
    int? notificationId,
    String? lastStockUpdateDate,
  }) {
    return MedicineSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      remainingStock: remainingStock ?? this.remainingStock,
      mealRule: mealRule ?? this.mealRule,
      time: time ?? this.time,
      type: type ?? this.type,
      medicineBox: medicineBox ?? this.medicineBox,
      notificationId: notificationId ?? this.notificationId,
      lastStockUpdateDate:
          lastStockUpdateDate ?? this.lastStockUpdateDate,
    );
  }

  String get dosageLabel => '$dose butir - $mealRule';

  bool isSameMedicine(MedicineSchedule other) {
    return medicineKey == other.medicineKey;
  }

  String get medicineKey => normalizeMedicineName(name);

  static String normalizeMedicineName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(999999);
    return '$timestamp-$random';
  }

  static int? _parsePositiveInt(dynamic value) {
    if (value == null) return null;
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();

    final text = value.toString();
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return null;

    final parsed = int.tryParse(match.group(0)!);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int _parseMedicineBox(dynamic value) {
    final parsed = _parsePositiveInt(value);
    if (parsed == null || parsed < 1 || parsed > 6) return 1;
    return parsed;
  }

  static String _normalizeType(dynamic value) {
    final type = value?.toString().toLowerCase();
    if (type == 'capsule' || type == 'kapsul') return 'capsule';
    return 'tablet';
  }

  static String? _extractMealRule(String? dosage) {
    if (dosage == null || dosage.isEmpty) return null;

    final parts = dosage.split(RegExp(r'\s*-\s*'));
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  static String? _parseNullableText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
