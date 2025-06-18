import 'package:flutter/material.dart';
import 'package:PersonalOS/models/classification_request.dart';
import 'package:PersonalOS/models/activity_session.dart';
import 'package:PersonalOS/widgets/classification_dialog.dart';
import 'package:PersonalOS/widgets/classification_dialog_for_group.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import 'package:intl/intl.dart';

class UnclassifiedScreen extends StatefulWidget {
  const UnclassifiedScreen({super.key});

  @override
  State<UnclassifiedScreen> createState() => _UnclassifiedScreenState();
}

class _UnclassifiedScreenState extends State<UnclassifiedScreen> with WidgetsBindingObserver {
  // Store provider reference to avoid context lookup in dispose()
  ActivityProvider? _activityProvider;
  
  // Track app lifecycle state to avoid redundant polling calls
  AppLifecycleState? _previousLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start polling when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      provider.startPolling();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save provider reference for safe access in dispose()
    _activityProvider = Provider.of<ActivityProvider>(context, listen: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Use saved provider reference instead of context lookup
    _activityProvider?.stopPolling();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Skip if this is the same state as before
    if (_previousLifecycleState == state) return;
    
    final provider = _activityProvider ?? Provider.of<ActivityProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Only start polling if we were previously in a background state
        if (_isBackgroundState(_previousLifecycleState)) {
          provider.startPolling();
          provider.fetchUnclassifiedData();
          print("App resumed - polling started");
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Only stop polling if we were previously in a foreground state
        if (_isForegroundState(_previousLifecycleState)) {
          provider.stopPolling();
          print("App backgrounded - polling stopped");
        }
        break;
    }
    
    _previousLifecycleState = state;
  }

  bool _isForegroundState(AppLifecycleState? state) {
    return state == AppLifecycleState.resumed;
  }

  bool _isBackgroundState(AppLifecycleState? state) {
    return state == AppLifecycleState.paused ||
           state == AppLifecycleState.inactive ||
           state == AppLifecycleState.detached ||
           state == AppLifecycleState.hidden;
  }

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

  String _formatTimeRange(ActivitySession session) {
    if (session.startTime != null && session.endTime != null) {
      final startTime = DateFormat.jm().format(session.startTime!);
      final endTime = DateFormat.jm().format(session.endTime!);
      return "$startTime - $endTime (${_formatDuration(session.duration)})";
    } else {
      return "Duration: ${_formatDuration(session.duration)}";
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
                const SizedBox(height: 16),
                // Show polling status
                _buildPollingStatus(provider),
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
          child: Column(
            children: [
              // Show polling status indicator at the top
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildPollingStatus(provider),
                    const Spacer(),
                    Text(
                      "${sortedAppNames.length} app${sortedAppNames.length == 1 ? '' : 's'} to classify",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
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
                              _formatTimeRange(session),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollingStatus(ActivityProvider provider) {
    if (provider.isPollingActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            "Auto-refreshing every minute",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            "Auto-refresh stopped",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      );
    }
  }
}