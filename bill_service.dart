import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/bill.dart';

/// Manages bill history, runs prediction, and raises high-usage alerts.
///
/// Two prediction paths are supported:
/// 1. Local fallback algorithm (works fully offline, no backend needed).
/// 2. Remote call to your Python FastAPI + ML backend (recommended for
///    production-quality prediction). Set [backendBaseUrl] to enable it.
class BillService extends ChangeNotifier {
  final List<Bill> _bills = [];
  List<Bill> get bills => List.unmodifiable(_bills);

  /// Point this at your FastAPI server, e.g. http://10.0.2.2:8000
  /// Leave null to use only the local prediction algorithm.
  String? backendBaseUrl;

  static const _storageKey = 'bill_history';

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _bills.clear();
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _bills.addAll(list.map((e) => Bill.fromJson(e)));
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_bills.map((b) => b.toJson()).toList()),
    );
  }

  Bill? get latestBill => _bills.isEmpty ? null : _bills.last;

  /// Adds a new month's bill entry, runs prediction, and persists it.
  Future<Bill> addBillEntry({
    required String month,
    required double previousBillAmount,
    required double currentBillAmount,
    double? unitsConsumed,
  }) async {
    final bill = Bill(
      month: month,
      previousBillAmount: previousBillAmount,
      currentBillAmount: currentBillAmount,
      unitsConsumed: unitsConsumed,
    );

    bill.predictedNextBill = await predictNextBill(bill);

    _bills.add(bill);
    await _saveToStorage();
    notifyListeners();
    return bill;
  }

  /// Predicts next month's bill.
  /// Tries the FastAPI/ML backend first (if configured), falls back to a
  /// local weighted-trend estimate otherwise.
  Future<double> predictNextBill(Bill latest) async {
    if (backendBaseUrl != null) {
      try {
        final response = await http.post(
          Uri.parse('$backendBaseUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'history': _bills.map((b) => b.toJson()).toList(),
            'current_bill': latest.toJson(),
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return (data['predicted_bill'] as num).toDouble();
        }
      } catch (_) {
        // fall through to local algorithm if backend is unreachable
      }
    }
    return _localPrediction(latest);
  }

  /// Simple, dependable fallback: extrapolates from the recent trend.
  /// growth% = average of last few months' % change, applied to current bill.
  double _localPrediction(Bill latest) {
    final history = [..._bills, latest];
    if (history.length < 2) {
      // not enough data yet — assume +5% seasonal buffer
      return latest.currentBillAmount * 1.05;
    }
    final recent = history.length > 4
        ? history.sublist(history.length - 4)
        : history;

    final changes = <double>[];
    for (var i = 1; i < recent.length; i++) {
      final prev = recent[i - 1].currentBillAmount;
      final curr = recent[i].currentBillAmount;
      if (prev > 0) changes.add((curr - prev) / prev);
    }
    final avgChange =
        changes.isEmpty ? 0.05 : changes.reduce((a, b) => a + b) / changes.length;

    return latest.currentBillAmount * (1 + avgChange);
  }

  /// Whether the latest bill should trigger a high-usage alert.
  bool get shouldAlert =>
      latestBill != null && latestBill!.status != BillStatus.normal;

  String alertMessageEnglish() {
    final b = latestBill!;
    final pct = b.percentChange.toStringAsFixed(0);
    return '⚠️ Your electricity usage is increasing!\n'
        'Your bill increased by $pct% compared with last month.';
  }

  String alertMessageTamil() {
    final b = latestBill!;
    final pct = b.percentChange.toStringAsFixed(0);
    return '⚠️ உங்கள் மின்சார பயன்பாடு அதிகரித்து வருகிறது!\n'
        'கடந்த மாதத்துடன் ஒப்பிடும்போது உங்கள் பில் $pct% அதிகரித்துள்ளது.';
  }

  List<String> energySavingTips() => const [
        'AC usage reduce பண்ணவும் (thermostat 24–26°C-ல் வையுங்க)',
        'Unused appliances switch off பண்ணவும்',
        'LED bulbs use பண்ணவும்',
        'Peak hours-ல் heavy appliances (washing machine, iron) தவிர்க்கவும்',
      ];
}
