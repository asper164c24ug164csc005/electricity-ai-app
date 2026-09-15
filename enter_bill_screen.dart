import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/bill_service.dart';

class EnterBillScreen extends StatefulWidget {
  const EnterBillScreen({super.key});

  @override
  State<EnterBillScreen> createState() => _EnterBillScreenState();
}

class _EnterBillScreenState extends State<EnterBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prevCtrl = TextEditingController();
  final _currCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  DateTime _selectedMonth = DateTime.now();
  bool _saving = false;

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select bill month',
    );
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    final bill = await context.read<BillService>().addBillEntry(
          month: monthLabel,
          previousBillAmount: double.parse(_prevCtrl.text),
          currentBillAmount: double.parse(_currCtrl.text),
          unitsConsumed:
              _unitsCtrl.text.isEmpty ? null : double.parse(_unitsCtrl.text),
        );

    setState(() => _saving = false);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Saved. Predicted next month: ₹${bill.predictedNextBill?.toStringAsFixed(0)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Bill Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                subtitle: const Text('Bill month'),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickMonth,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prevCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Previous month bill amount (₹)',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _currCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Current month bill amount (₹)',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unitsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Units consumed (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save & Predict'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
