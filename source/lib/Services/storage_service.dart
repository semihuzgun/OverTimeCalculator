import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Aylık brüt kayıtlarını telefonda saklar.
/// 12 aylık yapı: Ocak–Aralık
/// Kümülatif = tüm ayların toplamı
class StorageService {
  static const _keyMonthlyBrut = 'monthly_brut';

  static const _monthNames = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  static String _storageKey(int year) => '${_keyMonthlyBrut}_$year';

  /// Yılın 12 ayı için tutarları getirir. Ay: 1–12
  static Future<Map<int, double>> getMonthlyValues(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey(year));
    if (json == null) return {};

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final result = <int, double>{};
      for (final e in map.entries) {
        final month = int.tryParse(e.key);
        if (month != null && month >= 1 && month <= 12) {
          final val = e.value;
          if (val is num) {
            result[month] = val.toDouble();
          } else if (val is String) {
            result[month] = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
          } else {
            result[month] = 0.0;
          }
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Belirli bir ayın tutarını kaydeder. month: 1–12
  static Future<void> setMonthValue(int year, int month, double amount) async {
    final values = await getMonthlyValues(year);
    values[month] = amount;
    await _saveMonthlyValues(year, values);
  }

  /// Tüm ayları bir seferde kaydeder
  static Future<void> saveMonthlyValues(int year, Map<int, double> values) async {
    await _saveMonthlyValues(year, values);
  }

  static Future<void> _saveMonthlyValues(int year, Map<int, double> values) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = values.map((k, v) => MapEntry(k.toString(), v.toStringAsFixed(2)));
    await prefs.setString(_storageKey(year), jsonEncode(encoded));
  }

  /// "Bu ayı kaydet" için: ay adından (örn. Ocak 2026) kaydeder
  static Future<void> addEntry(String monthLabel, double amount) async {
    final parts = monthLabel.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;
    int? month;
    int? year;
    for (var i = 0; i < _monthNames.length; i++) {
      if (parts[0].toLowerCase().startsWith(_monthNames[i].toLowerCase())) {
        month = i + 1;
        break;
      }
    }
    year = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (month == null || year == null) return;
    await setMonthValue(year, month, amount);
  }

  static Future<double> getCumulativeTotal({required int untilMonth}) async {
    final values = await getMonthlyValues(DateTime.now().year);
    var total = 0.0;
    for (var m = 1; m < untilMonth; m++) {
      total += values[m] ?? 0;
    }
    return total;
  }

  static String monthLabel(int year, int month) {
    if (month < 1 || month > 12) return '';
    return '${_monthNames[month - 1]} $year';
  }

  // ---- Son girdiler (aylık brüt ekranı) ----
  static const _keyLastInputs = 'last_inputs';

  static Future<void> saveLastInputs({
    required double gross,
    required double cumulative,
    required double hours1,
    required double rate1,
    required double hours2,
    required double rate2,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastInputs, jsonEncode({
      'gross': gross,
      'cumulative': cumulative,
      'hours1': hours1,
      'rate1': rate1,
      'hours2': hours2,
      'rate2': rate2,
    }));
  }

  static Future<Map<String, double>?> loadLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyLastInputs);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _parseInputsMap(map);
    } catch (_) {
      return null;
    }
  }

  // ---- Son girdiler (saatlik ücret ekranı) ----
  static const _keyLastInputsHourly = 'last_inputs_hourly';

  static Future<void> saveLastInputsHourly({
    required double hourly,
    required double cumulative,
    required double hours1,
    required double rate1,
    required double hours2,
    required double rate2,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastInputsHourly, jsonEncode({
      'hourly': hourly,
      'cumulative': cumulative,
      'hours1': hours1,
      'rate1': rate1,
      'hours2': hours2,
      'rate2': rate2,
    }));
  }

  static Future<Map<String, double>?> loadLastInputsHourly() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyLastInputsHourly);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _parseInputsMap(map);
    } catch (_) {
      return null;
    }
  }

  static Map<String, double> _parseInputsMap(Map<String, dynamic> map) {
    return map.map((k, v) {
      if (v is num) {
        return MapEntry(k, v.toDouble());
      }
      if (v is String) {
        return MapEntry(k, double.tryParse(v.replaceAll(',', '.')) ?? 0.0);
      }
      return MapEntry(k, 0.0);
    });
  }
}