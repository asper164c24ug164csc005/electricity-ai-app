import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with a pre-filled high-usage alert message.
/// For fully automatic (no user tap) sending, you'd instead call the
/// WhatsApp Business API from your FastAPI backend — this client-side
/// approach opens a chat with the message ready to send.
class WhatsAppService {
  static Future<bool> sendAlert({
    required String phoneNumber, // e.g. "91XXXXXXXXXX" (country code, no +)
    required String englishMessage,
    required String tamilMessage,
  }) async {
    final text = Uri.encodeComponent('$englishMessage\n\n$tamilMessage');
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$text');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
