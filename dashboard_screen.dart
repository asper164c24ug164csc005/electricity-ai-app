import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/bill_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/bill_card.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/tip_card.dart';
import '../bill_entry/enter_bill_screen.dart';
import '../history/bill_history_screen.dart';
import '../assistant/ai_assistant_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final billService = context.watch<BillService>();
    final latest = billService.latestBill;
    final history = billService.bills;
    final previous =
        history.length >= 2 ? history[history.length - 2] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${auth.currentUser?.name.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: billService.loadFromStorage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: BillCard(
                    label: 'Previous Bill',
                    amount: previous?.currentBillAmount ??
                        latest?.previousBillAmount,
                    icon: Icons.history,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BillCard(
                    label: 'Current Bill',
                    amount: latest?.currentBillAmount,
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BillCard(
              label: 'Predicted Next Month Bill',
              amount: latest?.predictedNextBill,
              icon: Icons.auto_graph,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            if (billService.shouldAlert)
              AlertBanner(
                englishMessage: billService.alertMessageEnglish(),
                tamilMessage: billService.alertMessageTamil(),
                onSendWhatsApp: () => WhatsAppService.sendAlert(
                  phoneNumber: '91XXXXXXXXXX', // TODO: use stored user phone
                  englishMessage: billService.alertMessageEnglish(),
                  tamilMessage: billService.alertMessageTamil(),
                ),
              ),
            const SizedBox(height: 8),
            TipCard(tips: billService.energySavingTips()),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Enter Bill'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EnterBillScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('History'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BillHistoryScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Ask AI Assistant'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
