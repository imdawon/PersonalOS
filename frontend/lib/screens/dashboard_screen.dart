import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todaySummary.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.todaySummary.isEmpty) {
          return const Center(
            child: Text('No classified activity for today yet.', style: TextStyle(fontSize: 18)),
          );
        }

        double totalDuration = provider.todaySummary.fold(0, (sum, item) => sum + item.totalDuration);
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sections: provider.todaySummary.map((item) {
                final percentage = (item.totalDuration / totalDuration) * 100;
                return PieChartSectionData(
                  color: _getColorForActivity(item.userDefinedName),
                  value: item.totalDuration.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        );
      },
    );
  }
  // Simple deterministic color generator for categories
  Color _getColorForActivity(String name) {
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 1);
  }
}