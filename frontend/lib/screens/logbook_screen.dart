import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/logbook_models.dart';
import '../widgets/reclassification_dialog.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  Set<int> _selectedSessions = {};
  bool _isMultiSelectMode = false;

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

        return RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) {
            if (event is RawKeyDownEvent) {
              if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
                // Shift+A to select all
                setState(() {
                  _isMultiSelectMode = true;
                  for (final activity in provider.recentActivities) {
                    _selectedSessions.add(activity.sessionId);
                  }
                });
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                // Escape to exit multi-select mode
                setState(() {
                  _selectedSessions.clear();
                  _isMultiSelectMode = false;
                });
              }
            }
          },
          child: RefreshIndicator(
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
        // Create simplified rule text - only include window title if it's not empty
        String ruleText;
        if (rule.windowTitleContains.isEmpty) {
          ruleText = 'If App is "${rule.appName}"';
        } else {
          ruleText = 'If App is "${rule.appName}" and Window Title contains "${rule.windowTitleContains}"';
        }
        
        return Card(
          child: ListTile(
            title: Text(ruleText),
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

    // Group activities by classification name and time proximity
    final Map<String, List<List<RecentActivityInfo>>> groupedActivities = _groupActivitiesByClassificationAndTime(provider.recentActivities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multi-select controls
        if (_isMultiSelectMode) _buildMultiSelectControls(context, provider),
        ...groupedActivities.entries.map((entry) {
          final classificationName = entry.key;
          final activityGroups = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classificationName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activityGroups.fold<int>(0, (sum, group) => sum + group.length)} events',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              children: activityGroups.map((activityGroup) {
                if (activityGroup.length == 1) {
                  return _buildSingleActivity(context, activityGroup.first, provider);
                } else {
                  return _buildActivityGroup(context, activityGroup, provider);
                }
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Map<String, List<List<RecentActivityInfo>>> _groupActivitiesByClassificationAndTime(List<RecentActivityInfo> activities) {
    final Map<String, List<RecentActivityInfo>> byClassification = {};
    
    // First group by classification
    for (final activity in activities) {
      byClassification.putIfAbsent(activity.userDefinedName, () => []);
      byClassification[activity.userDefinedName]!.add(activity);
    }

    // Then group by time proximity within each classification
    final Map<String, List<List<RecentActivityInfo>>> result = {};
    
    byClassification.forEach((classification, activities) {
      // Sort by start time
      activities.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      final List<List<RecentActivityInfo>> groups = [];
      List<RecentActivityInfo> currentGroup = [];
      
      for (int i = 0; i < activities.length; i++) {
        if (currentGroup.isEmpty) {
          currentGroup.add(activities[i]);
        } else {
          // Check if this activity is within 5 minutes of the previous one
          final lastActivity = currentGroup.last;
          final timeDiff = (lastActivity.startTime - activities[i].startTime).abs();
          
          if (timeDiff <= 300 && // 5 minutes in seconds
              lastActivity.appName == activities[i].appName &&
              lastActivity.windowTitle == activities[i].windowTitle) {
            currentGroup.add(activities[i]);
          } else {
            groups.add(List.from(currentGroup));
            currentGroup = [activities[i]];
          }
        }
      }
      
      if (currentGroup.isNotEmpty) {
        groups.add(currentGroup);
      }
      
      result[classification] = groups;
    });
    
    return result;
  }

  Widget _buildMultiSelectControls(BuildContext context, ActivityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.select_all, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${_selectedSessions.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedSessions.isEmpty ? null : () {
                    _showDeleteMultipleConfirmation(context, provider);
                  },
                  child: const Text('Delete Selected'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSessions.clear();
                      _isMultiSelectMode = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Use Shift+A to select all, Escape to cancel, or long-press to enter multi-select mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleActivity(BuildContext context, RecentActivityInfo activity, ActivityProvider provider) {
    final isSelected = _selectedSessions.contains(activity.sessionId);
    final time = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(activity.startTime * 1000)
    );
    
    return Padding(
      padding: const EdgeInsets.only(left: 26.0, bottom: 4.0),
      child: InkWell(
        onTap: () => _handleActivityTap(activity),
        onLongPress: () => _enterMultiSelectMode(activity),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSelection(activity.sessionId),
                ),
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
                  if (!_isMultiSelectMode) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: () => _showReclassificationDialog(context, activity, provider),
                      tooltip: 'Edit classification',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      iconSize: 16,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined, size: 16),
                      onPressed: () => _showDeleteConfirmation(context, activity, provider),
                      tooltip: 'Delete session',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      iconSize: 16,
                    ),
                  ],
                  const SizedBox(width: 4),
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
        ),
      ),
    );
  }

  Widget _buildActivityGroup(BuildContext context, List<RecentActivityInfo> activities, ActivityProvider provider) {
    final firstActivity = activities.first;
    final lastActivity = activities.last;
    final startTime = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(lastActivity.startTime * 1000)
    );
    final endTime = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(firstActivity.startTime * 1000)
    );
    
    return Padding(
      padding: const EdgeInsets.only(left: 26.0, bottom: 4.0),
      child: ExpansionTile(
        title: Row(
          children: [
            if (_isMultiSelectMode)
              Checkbox(
                value: activities.every((a) => _selectedSessions.contains(a.sessionId)),
                onChanged: (value) {
                  if (value == true) {
                    setState(() {
                      for (final activity in activities) {
                        _selectedSessions.add(activity.sessionId);
                      }
                    });
                  } else {
                    setState(() {
                      for (final activity in activities) {
                        _selectedSessions.remove(activity.sessionId);
                      }
                    });
                  }
                },
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstActivity.windowTitle.isNotEmpty 
                        ? firstActivity.windowTitle 
                        : firstActivity.appName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (firstActivity.windowTitle.isNotEmpty)
                    Text(
                      firstActivity.appName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${activities.length} events',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: activities.map((activity) => _buildSingleActivity(context, activity, provider)).toList(),
      ),
    );
  }

  void _handleActivityTap(RecentActivityInfo activity) {
    if (_isMultiSelectMode) {
      _toggleSelection(activity.sessionId);
    }
  }

  void _enterMultiSelectMode(RecentActivityInfo activity) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedSessions.add(activity.sessionId);
    });
  }

  void _toggleSelection(int sessionId) {
    setState(() {
      if (_selectedSessions.contains(sessionId)) {
        _selectedSessions.remove(sessionId);
      } else {
        _selectedSessions.add(sessionId);
      }
    });
  }

  void _showDeleteMultipleConfirmation(BuildContext context, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Multiple Sessions'),
          content: Text('Are you sure you want to delete ${_selectedSessions.length} selected sessions?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                for (final sessionId in _selectedSessions) {
                  provider.deleteSession(sessionId);
                }
                setState(() {
                  _selectedSessions.clear();
                  _isMultiSelectMode = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showReclassificationDialog(BuildContext context, RecentActivityInfo activity, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReclassificationDialog(
          currentClassification: activity.userDefinedName,
          existingClassifications: provider.existingClassifications,
          onReclassify: (userDefinedName, isHelpful, goalContext, createRule) {
            provider.reclassifySession(
              activity.sessionId,
              userDefinedName,
              isHelpful,
              goalContext,
            );
            // TODO: Handle createRule if needed for reclassification
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, RecentActivityInfo activity, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this activity session?'),
              const SizedBox(height: 8),
              Text(
                'Activity: ${activity.userDefinedName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'App: ${activity.appName}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (activity.windowTitle.isNotEmpty)
                Text(
                  'Window: ${activity.windowTitle}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                provider.deleteSession(activity.sessionId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 