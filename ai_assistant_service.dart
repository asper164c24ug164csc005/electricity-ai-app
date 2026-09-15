import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill.dart';

/// Talks to your FastAPI backend, which in turn calls the Gemini API
/// with the user's stored bill history to answer questions like
/// "Why is my bill increasing?".
class AiAssistantService {
  final String backendBaseUrl; // e.g. http://10.0.2.2:8000

  AiAssistantService({required this.backendBaseUrl});

  Future<String> ask(String question, List<Bill> history) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/assistant/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'history': history.map((b) => b.toJson()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] as String;
      }
      return 'Sorry, I could not reach the assistant right now.';
    } catch (_) {
      // Offline fallback so the UI still demonstrates behavior
      return _localFallback(question, history);
    }
  }

  String _localFallback(String question, List<Bill> history) {
    if (history.length < 2) {
      return "Not enough bill history yet to explain trends — add a couple more months of data.";
    }
    final latest = history.last;
    final prev = history[history.length - 2];
    final diff = latest.currentBillAmount - prev.currentBillAmount;
    if (diff <= 0) {
      return 'Your usage actually went down or stayed flat compared to last month. Good job!';
    }
    return 'Your bill increased by ₹${diff.toStringAsFixed(0)} compared to last month. '
        'This is often due to higher AC/fan usage, more appliance runtime, or seasonal heat. '
        'Try reducing AC hours, switching to LED bulbs, and unplugging unused devices.';
  }
}
