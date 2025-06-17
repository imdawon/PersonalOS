import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

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
    return Column(
      children: provider.recentActivities.map((activity) {
        final time = DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000));
        return Card(
          child: ListTile(
            title: Text(activity.windowTitle.isNotEmpty ? activity.windowTitle : activity.appName),
            subtitle: Text('${activity.appName} -> ${activity.userDefinedName}'),
            trailing: Text(time),
          ),
        );
      }).toList(),
    );
  }
} 