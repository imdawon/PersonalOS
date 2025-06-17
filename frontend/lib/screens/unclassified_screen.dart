import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/classification_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class UnclassifiedScreen extends StatelessWidget {
  const UnclassifiedScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.unclassifiedSessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.unclassifiedSessions.isEmpty) {
          return const Center(
            child: Text('All activities classified! 🎉', style: TextStyle(fontSize: 18)),
          );
        }

        return ListView.builder(
          itemCount: provider.unclassifiedSessions.length,
          itemBuilder: (context, index) {
            final session = provider.unclassifiedSessions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(session.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(session.windowTitle),
                trailing: Text(_formatDuration(session.duration)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ClassificationDialog(session: session);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}