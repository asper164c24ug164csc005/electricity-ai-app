enum BillStatus { normal, increased, high }

class Bill {
  final String month; // e.g. "September 2026"
  final double previousBillAmount;
  final double currentBillAmount;
  final double? unitsConsumed;
  double? predictedNextBill;

  Bill({
    required this.month,
    required this.previousBillAmount,
    required this.currentBillAmount,
    this.unitsConsumed,
    this.predictedNextBill,
  });

  /// % change vs previous bill
  double get percentChange {
    if (previousBillAmount == 0) return 0;
    return ((currentBillAmount - previousBillAmount) / previousBillAmount) * 100;
  }

  BillStatus get status {
    final change = percentChange;
    if (change >= 20) return BillStatus.high;
    if (change > 0) return BillStatus.increased;
    return BillStatus.normal;
  }

  String get statusLabel {
    switch (status) {
      case BillStatus.high:
        return 'High';
      case BillStatus.increased:
        return 'Increased';
      case BillStatus.normal:
        return 'Normal';
    }
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'previousBillAmount': previousBillAmount,
        'currentBillAmount': currentBillAmount,
        'unitsConsumed': unitsConsumed,
        'predictedNextBill': predictedNextBill,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        month: json['month'],
        previousBillAmount: (json['previousBillAmount'] as num).toDouble(),
        currentBillAmount: (json['currentBillAmount'] as num).toDouble(),
        unitsConsumed: json['unitsConsumed'] != null
            ? (json['unitsConsumed'] as num).toDouble()
            : null,
        predictedNextBill: json['predictedNextBill'] != null
            ? (json['predictedNextBill'] as num).toDouble()
            : null,
      );
}
