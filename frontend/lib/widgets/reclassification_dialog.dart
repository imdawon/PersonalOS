import 'package:flutter/material.dart';
import '../models/logbook_models.dart';
import 'scrollable_fade_container.dart';

class ReclassificationDialog extends StatefulWidget {
  final String currentClassification;
  final List<ExistingClassification> existingClassifications;
  final Function(String userDefinedName, bool isHelpful, String goalContext, bool createRule) onReclassify;

  const ReclassificationDialog({
    super.key,
    required this.currentClassification,
    required this.existingClassifications,
    required this.onReclassify,
  });

  @override
  State<ReclassificationDialog> createState() => _ReclassificationDialogState();
}

class _ReclassificationDialogState extends State<ReclassificationDialog> {
  late TextEditingController _customActivityController;
  
  // Preset activity categories with icons (same as original dialog)
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
    
    // Pre-select the current classification
    _selectedActivity = widget.currentClassification;
    
    // Find the current classification in existing ones to set context and helpful status
    final existingMatch = widget.existingClassifications
        .where((c) => c.userDefinedName == widget.currentClassification)
        .firstOrNull;
    
    if (existingMatch != null) {
      _isHelpful = existingMatch.isHelpful;
      _goalContext = existingMatch.goalContext;
      _isCustomActivity = false;
    } else {
      // Check if it's one of the preset activities
      final presetMatch = _presetActivities
          .where((activity) => activity['name'] == widget.currentClassification)
          .firstOrNull;
      
      if (presetMatch != null) {
        _goalContext = presetMatch['context'];
        _isHelpful = presetMatch['context'] != 'Wasting Time';
        _isCustomActivity = false;
      } else {
        // It's a custom activity
        _customActivityController.text = widget.currentClassification;
        _isCustomActivity = true;
      }
    }
  }

  @override
  void dispose() {
    _customActivityController.dispose();
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

  void _selectActivity(String activityName, String defaultContext, bool defaultHelpful) {
    setState(() {
      _selectedActivity = activityName;
      _isCustomActivity = false;
      _goalContext = defaultContext;
      _isHelpful = defaultHelpful;
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

    widget.onReclassify(finalActivityName, _isHelpful, _goalContext, _createRule);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text(
                    'Reclassify Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Scrollable content with fade indicator
            Expanded(
              child: ScrollableFadeContainer(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
            Text(
              'Currently: ${widget.currentClassification}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Activity Selection Header
            const Row(
              children: [
                Text('🔖', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Select Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Activity Grid
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Existing classifications first (if any)
                    ...widget.existingClassifications.map((classification) {
                      final isSelected = _selectedActivity == classification.userDefinedName;
                      // Try to find an icon from presets, otherwise use default
                      final presetMatch = _presetActivities
                          .where((activity) => activity['name'] == classification.userDefinedName)
                          .firstOrNull;
                      final icon = presetMatch?['icon'] ?? '📝';
                      
                      return GestureDetector(
                        onTap: () => _selectActivity(
                          classification.userDefinedName, 
                          classification.goalContext,
                          classification.isHelpful,
                        ),
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
                              Text(icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                classification.userDefinedName,
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
                    
                    // Preset activities (only show ones not already in existing classifications)
                    ..._presetActivities.where((activity) {
                      return !widget.existingClassifications
                          .any((existing) => existing.userDefinedName == activity['name']);
                    }).map((activity) {
                      final isSelected = _selectedActivity == activity['name'];
                      return GestureDetector(
                        onTap: () => _selectActivity(
                          activity['name'], 
                          activity['context'],
                          activity['context'] != 'Wasting Time',
                        ),
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
            const Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
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
            const Row(
              children: [
                Text('🚀', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(
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
            
            const SizedBox(height: 24),
            
            // Create Automation Rule
            const Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Create Automation Rule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Checkbox(
                  value: _createRule,
                  onChanged: (value) => setState(() => _createRule = value!),
                ),
                const Expanded(
                  child: Text(
                    'Automatically classify similar activities in the future',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Update Classification'),
                ),
              ],
            ),
                   ],
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
     );
   }
 } 