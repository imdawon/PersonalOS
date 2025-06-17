import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting duration in tooltip
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/today_summary.dart'; // To use TodaySummaryItem

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _touchedIndex; // To keep track of the touched pie section for tooltips

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  // Consistent color generation for legend and chart
  final Map<String, Color> _activityColors = {};
  Color _getColorForActivity(String name) {
    if (_activityColors.containsKey(name)) {
      return _activityColors[name]!;
    }
    // Simple deterministic color generator
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    final color = Color.fromRGBO(r.clamp(50, 200), g.clamp(50, 200), b.clamp(50, 200), 1); // clamp to avoid too dark/light
    _activityColors[name] = color;
    return color;
  }
   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear colors when dependencies change, e.g., data reloads, to regenerate if needed
    // This is important if the list of activities can change dynamically and you want consistent colors for same activities
    // For now, let's keep it simple. If activities change, colors might shift if not handled carefully.
    // A better approach for persistent colors would be to store them more globally or associate with classification ID.
    // For v0, this dynamic generation on build is okay.
     _activityColors.clear(); // Clear to re-generate if data changes
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todaySummary.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.todaySummary.isEmpty) {
           return Center(child: Text("Error: ${provider.error}"));
        }

        if (provider.todaySummary.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No classified activity for today yet.', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Go to the "Classify" tab to label your time!', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        double totalDurationForAllActivities = provider.todaySummary.fold(0, (sum, item) => sum + item.totalDuration);
        
        // Reset touchedIndex if the data changes and the old index is out of bounds
        if (_touchedIndex != null && _touchedIndex! >= provider.todaySummary.length) {
            _touchedIndex = null;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                flex: 2, // Give more space to the chart
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1; // -1 to clear selection
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60, // Increased for a more "donut" look
                    sections: List.generate(provider.todaySummary.length, (i) {
                      final isTouched = i == _touchedIndex;
                      final item = provider.todaySummary[i];
                      final fontSize = isTouched ? 18.0 : 14.0;
                      final radius = isTouched ? 110.0 : 100.0;
                      final percentage = (item.totalDuration / totalDurationForAllActivities) * 100;
                      final color = _getColorForActivity(item.userDefinedName);

                      return PieChartSectionData(
                        color: color,
                        value: item.totalDuration.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%', // Simpler percentage
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                           shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                        // Tooltip (alternative to external tooltip)
                        // badgeWidget: isTouched ? _buildBadge(item.userDefinedName, color) : null,
                        // badgePositionPercentageOffset: .98,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              Expanded(
                flex: 1, // Give space for the legend
                child: Wrap( // Use Wrap for legend items to flow
                  spacing: 10.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: provider.todaySummary.map((item) {
                    final color = _getColorForActivity(item.userDefinedName);
                    final isTouched = provider.todaySummary.indexOf(item) == _touchedIndex;
                    return InkWell(
                      onTap: () {
                         setState(() {
                           _touchedIndex = provider.todaySummary.indexOf(item);
                         });
                      },
                      child: Chip(
                        avatar: CircleAvatar(backgroundColor: color, radius: 8),
                        label: Text(
                          '${item.userDefinedName} (${_formatDuration(item.totalDuration)})',
                          style: TextStyle(
                            fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                            fontSize: isTouched ? 13 : 12,
                          ),
                        ),
                        backgroundColor: isTouched ? color.withOpacity(0.3) : Theme.of(context).chipTheme.backgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Optional: If you want a badge directly on the chart for the touched section
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}