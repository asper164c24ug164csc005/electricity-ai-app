import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bill.dart';

class BillChart extends StatelessWidget {
  final List<Bill> bills;

  const BillChart({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No bill history yet')),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < bills.length; i++)
        FlSpot(i.toDouble(), bills[i].currentBillAmount),
    ];

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bills.length) return const SizedBox();
                  final label = bills[i].month.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label.substring(0, label.length.clamp(0, 3)),
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
