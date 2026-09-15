import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final String englishMessage;
  final String tamilMessage;
  final VoidCallback? onSendWhatsApp;

  const AlertBanner({
    super.key,
    required this.englishMessage,
    required this.tamilMessage,
    this.onSendWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(englishMessage,
              style: TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(tamilMessage, style: TextStyle(color: Colors.red.shade700)),
          if (onSendWhatsApp != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onSendWhatsApp,
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send alert to WhatsApp'),
            ),
          ]
        ],
      ),
    );
  }
}
