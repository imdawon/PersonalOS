import 'package:flutter/material.dart';
import 'package:PersonalOS/models/classification_request.dart';
import 'package:PersonalOS/widgets/classification_dialog.dart';
import 'package:PersonalOS/widgets/classification_dialog_for_group.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class UnclassifiedScreen extends StatelessWidget {
  const UnclassifiedScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    // final seconds = twoDigits(duration.inSeconds.remainder(60)); // Optionally show seconds
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        // Show loading spinner only when fetching initial data.
        if (provider.isLoading && provider.groupedUnclassifiedSessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // If there's nothing to classify, that's the most important state. Show success message.
        if (provider.groupedUnclassifiedSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text('All activities classified! 🎉', style: TextStyle(fontSize: 20)),
                 const SizedBox(height: 8),
                Text("Check your Dashboard tab.", style: TextStyle(fontSize: 16, color: Colors.grey[400])),
              ],
            ),
          );
        }

        // If we have data but there was an error fetching updates, show it.
        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUnclassifiedData(),
                    child: const Text('Try Again'),
                  )
                ],
              ),
            ),
          );
        }

        final sortedAppNames = provider.unclassifiedDurationPerApp.keys.toList();

        return RefreshIndicator(
          onRefresh: () => provider.fetchUnclassifiedData(),
          child: ListView.builder(
            itemCount: sortedAppNames.length,
            itemBuilder: (context, index) {
              final appName = sortedAppNames[index];
              final sessionsInGroup = provider.groupedUnclassifiedSessions[appName]!;
              final totalDurationForApp = provider.unclassifiedDurationPerApp[appName]!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ExpansionTile(
                  key: PageStorageKey<String>(appName), // Preserve expansion state
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          appName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDuration(totalDurationForApp),
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  // Custom trailing to place button before chevron
                  trailing: SizedBox( // Wrap in SizedBox to constrain width if needed
                    width: 48, // Adjust as needed, ensure enough space for icon + default chevron
                    child: IconButton(
                        icon: const Icon(Icons.playlist_add_check, color: Colors.blueAccent),
                        tooltip: 'Classify all in "$appName"',
                        padding: EdgeInsets.zero, // Reduce padding if icon looks too far
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return ClassificationDialogForGroup(
                                appName: appName,
                                itemCount: sessionsInGroup.length,
                              );
                            },
                          );
                        },
                      ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  children: sessionsInGroup.map((session) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      title: Text(
                        session.windowTitle.isNotEmpty ? session.windowTitle : '(No Window Title / App Focus)',
                        style: const TextStyle(fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDuration(session.duration),
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return ClassificationDialog(
                              session: session,
                              onSave: (String userDefinedName, bool isHelpful, String goalContext, bool createRule) {
                                final provider = Provider.of<ActivityProvider>(context, listen: false);
                                
                                if (createRule) {
                                  // Create rule with window title pattern
                                  provider.createRuleAndClassifyAppGroup(
                                    appName: session.appName,
                                    windowTitleContains: session.windowTitle.isNotEmpty ? session.windowTitle : '',
                                    userDefinedName: userDefinedName,
                                    isHelpful: isHelpful,
                                    goalContext: goalContext,
                                  );
                                } else {
                                  // Just classify this single session
                                  final request = ClassificationRequest(
                                    appName: session.appName,
                                    windowTitle: session.windowTitle,
                                    userDefinedName: userDefinedName,
                                    isHelpful: isHelpful,
                                    goalContext: goalContext,
                                  );
                                  provider.classifySingleSession(request);
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}