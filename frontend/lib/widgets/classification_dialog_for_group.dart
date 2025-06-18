// frontend/lib/widgets/classification_dialog_for_group.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class ClassificationDialogForGroup extends StatefulWidget {
  final String appName;
  final int itemCount;

  const ClassificationDialogForGroup({
    super.key,
    required this.appName,
    required this.itemCount,
  });

  @override
  State<ClassificationDialogForGroup> createState() => _ClassificationDialogForGroupState();
}

class _ClassificationDialogForGroupState extends State<ClassificationDialogForGroup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customActivityController;
  late TextEditingController _windowTitleContainsController;
  
  // Same preset activities as the single dialog
  static const List<Map<String, dynamic>> _presetActivities = [
    {'name': 'Programming', 'icon': '💻', 'context': 'Work'},
    {'name': 'Learning/Research', 'icon': '📚', 'context': 'Learn'},
    {'name': 'Browsing', 'icon': '🌐', 'context': 'Personal'},
    {'name': 'Communication', 'icon': '✉️', 'context': 'Work'},
    {'name': 'Social Media', 'icon': '📱', 'context': 'Wasting Time'},
    {'name': 'Entertainment', 'icon': '🎬', 'context': 'Relax'},
    {'name': 'Writing', 'icon': '✍️', 'context': 'Work'},
    {'name': 'Design', 'icon': '🎨', 'context': 'Work'},
    {'name': 'Planning', 'icon': '📅', 'context': 'Work'},
    {'name': 'Administration', 'icon': '📋', 'context': 'Admin'},
  ];

  String? _selectedActivity;
  bool _isCustomActivity = false;
  bool _isHelpful = true;
  String _goalContext = 'Work';
  bool _createRule = false;

  @override
  void initState() {
    super.initState();
    _customActivityController = TextEditingController();
    _windowTitleContainsController = TextEditingController();
    
    // Try to smart-suggest based on app name
    _suggestActivityFromApp();
  }

  void _suggestActivityFromApp() {
    final appName = widget.appName.toLowerCase();
    
    // Smart suggestions based on app patterns
    if (appName.contains('code') || appName.contains('vscode') || 
        appName.contains('intellij') || appName.contains('xcode')) {
      _selectedActivity = 'Programming';
      _goalContext = 'Work';
    } else if (appName.contains('chrome') || appName.contains('firefox') || 
               appName.contains('safari') || appName.contains('browser')) {
      _selectedActivity = 'Browsing';
      _goalContext = 'Personal';
    } else if (appName.contains('slack') || appName.contains('teams') || 
               appName.contains('discord') || appName.contains('mail')) {
      _selectedActivity = 'Communication';
      _goalContext = 'Work';
    }
  }

  @override
  void dispose() {
    _customActivityController.dispose();
    _windowTitleContainsController.dispose();
    super.dispose();
  }

  Color _getGoalContextColor(String context) {
    switch (context) {
      case 'Work': return Colors.blue;
      case 'Learn': return Colors.purple;
      case 'Personal': return Colors.green;
      case 'Relax': return Colors.orange;
      case 'Wasting Time': return Colors.red;
      case 'Admin': return Colors.grey;
      default: return Colors.blue;
    }
  }

  void _selectActivity(String activityName, String defaultContext) {
    setState(() {
      _selectedActivity = activityName;
      _isCustomActivity = false;
      _goalContext = defaultContext;
      // Smart default for helpfulness
      _isHelpful = defaultContext != 'Wasting Time';
    });
  }

  void _selectCustomActivity() {
    setState(() {
      _isCustomActivity = true;
      _selectedActivity = null;
    });
  }

  void _submitForm() {
    String finalActivityName;
    
    if (_isCustomActivity) {
      if (_customActivityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an activity name')),
        );
        return;
      }
      finalActivityName = _customActivityController.text.trim();
    } else {
      if (_selectedActivity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an activity')),
        );
        return;
      }
      finalActivityName = _selectedActivity!;
    }

    final provider = Provider.of<ActivityProvider>(context, listen: false);

    if (_createRule) {
      provider.createRuleAndClassifyAppGroup(
        appName: widget.appName,
        windowTitleContains: _windowTitleContainsController.text,
        userDefinedName: finalActivityName,
        isHelpful: _isHelpful,
        goalContext: _goalContext,
      );
    } else {
      provider.classifyAppGroup(
        widget.appName,
        finalActivityName,
        _isHelpful,
        _goalContext,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 600), // Add height constraint
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // Make it scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('🔖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Classify All Activities',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // App Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.appName.isNotEmpty 
                        ? widget.appName.substring(0, 1).toUpperCase()
                        : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${widget.itemCount} unclassified sessions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Activity Selection
            Row(
              children: [
                const Text('📂', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'What were you doing?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
                         // Activity Grid
             Container(
               constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Preset activities
                    ..._presetActivities.map((activity) {
                      final isSelected = _selectedActivity == activity['name'];
                      return GestureDetector(
                        onTap: () => _selectActivity(activity['name'], activity['context']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(activity['icon'], style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                activity['name'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Add custom activity option
                    GestureDetector(
                      onTap: _selectCustomActivity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCustomActivity 
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isCustomActivity 
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('➕', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text(
                              'Add new...',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Custom activity input
            if (_isCustomActivity) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customActivityController,
                decoration: const InputDecoration(
                  hintText: 'Enter activity name...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                autofocus: true,
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Goal Context
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'Goal Context',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Work', 'Learn', 'Personal', 'Relax', 'Wasting Time', 'Admin']
                  .map((goalContext) {
                final isSelected = _goalContext == goalContext;
                final color = _getGoalContextColor(goalContext);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _goalContext = goalContext;
                      // Auto-adjust helpfulness for "Wasting Time"
                      if (goalContext == 'Wasting Time') {
                        _isHelpful = false;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      goalContext,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? color : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Goal Progress Question
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Is this moving you towards your goals?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isHelpful,
                  onChanged: (value) => setState(() => _isHelpful = value!),
                ),
                const Text('Yes', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _isHelpful,
                  onChanged: (value) => setState(() => _isHelpful = value!),
                ),
                const Text('No', style: TextStyle(fontSize: 14)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Automation Rule
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Text(
                        'Create automation rule?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Switch(
                        value: _createRule,
                        onChanged: (value) => setState(() => _createRule = value),
                      ),
                    ],
                  ),
                  if (_createRule) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _windowTitleContainsController,
                      decoration: const InputDecoration(
                        labelText: 'If window title contains...',
                        hintText: 'Optional - leave empty to match any',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Will auto-classify future activities from "${widget.appName}" that match the criteria',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Save for All (${widget.itemCount})'),
                  ),
                ),
              ],
            ),
          ],
         ), // Close Column
        ), // Close SingleChildScrollView
      ),
    );
  }
}