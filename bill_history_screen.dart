import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bill_service.dart';
import '../../models/bill.dart';
import '../../widgets/bill_chart.dart';

class BillHistoryScreen extends StatelessWidget {
  const BillHistoryScreen({super.key});

  Color _statusColor(BillStatus status) {
    switch (status) {
      case BillStatus.high:
        return Colors.red;
      case BillStatus.increased:
        return Colors.orange;
      case BillStatus.normal:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillService>().bills;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill History')),
      body: bills.isEmpty
          ? const Center(child: Text('No bills added yet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BillChart(bills: bills),
                  ),
                ),
                const SizedBox(height: 16),
                ...bills.reversed.map(
                  (b) => Card(
                    child: ListTile(
                      title: Text(b.month),
                      subtitle: Text('₹${b.currentBillAmount.toStringAsFixed(0)}'),
                      trailing: Chip(
                        label: Text(b.statusLabel,
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: _statusColor(b.status),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
