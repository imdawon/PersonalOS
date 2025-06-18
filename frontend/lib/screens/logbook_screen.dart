import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/logbook_models.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.rules.isEmpty && provider.recentActivities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text("Error: ${provider.error}"));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAllData(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle(context, 'Automation Rules', Icons.smart_toy_outlined),
              const SizedBox(height: 8),
              _buildRulesList(context, provider),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Recent Activity', Icons.history),
              const SizedBox(height: 8),
              _buildRecentActivityList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildRulesList(BuildContext context, ActivityProvider provider) {
    if (provider.rules.isEmpty) {
      return const Text('No automation rules created yet.');
    }
    return Column(
      children: provider.rules.map((rule) {
        return Card(
          child: ListTile(
            title: Text('If App is "${rule.appName}" and Window Title contains "${rule.windowTitleContains}"'),
            subtitle: Text('Classify as: ${rule.userDefinedName}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => provider.deleteRule(rule.id),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, ActivityProvider provider) {
    if (provider.recentActivities.isEmpty) {
      return const Text('No recent classified activity.');
    }

    // Group activities by classification name (userDefinedName)
    final Map<String, List<RecentActivityInfo>> groupedActivities = {};
    for (final activity in provider.recentActivities) {
      if (!groupedActivities.containsKey(activity.userDefinedName)) {
        groupedActivities[activity.userDefinedName] = [];
      }
      groupedActivities[activity.userDefinedName]!.add(activity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedActivities.entries.map((entry) {
        final classificationName = entry.key;
        final activities = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Classification header
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      classificationName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activities.length} session${activities.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Activities in this classification
                ...activities.map((activity) {
                  final time = DateFormat.jm().format(
                    DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000)
                  );
                  return Padding(
                    padding: const EdgeInsets.only(left: 26.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.windowTitle.isNotEmpty 
                                    ? activity.windowTitle 
                                    : activity.appName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (activity.windowTitle.isNotEmpty)
                                Text(
                                  activity.appName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activity.isAuto)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AUTO',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              time,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
} 