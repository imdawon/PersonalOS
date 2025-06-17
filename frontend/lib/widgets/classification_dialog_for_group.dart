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
  late TextEditingController _nameController;
  late TextEditingController _windowTitleContainsController;
  bool _isHelpful = true;
  String _goalContext = 'Work';
  bool _createRule = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _windowTitleContainsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _windowTitleContainsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);

      if (_createRule) {
        provider.createRuleAndClassifyAppGroup(
          appName: widget.appName,
          windowTitleContains: _windowTitleContainsController.text,
          userDefinedName: _nameController.text,
          isHelpful: _isHelpful,
          goalContext: _goalContext,
        );
      } else {
        provider.classifyAppGroup(
          widget.appName,
          _nameController.text,
          _isHelpful,
          _goalContext,
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Classify All in "${widget.appName}"'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "This will apply the same classification to ${widget.itemCount} unclassified activities from \"${widget.appName}\".",
                 style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Activity Name (e.g., Browsing)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _goalContext,
                decoration: const InputDecoration(labelText: 'Goal Context'),
                 items: ['Work', 'Learn', 'Relax', 'Personal', 'Wasting Time', 'Admin']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _goalContext = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is this helpful?'),
                value: _isHelpful,
                onChanged: (bool value) {
                  setState(() {
                    _isHelpful = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Create automation rule?'),
                subtitle: const Text('Automatically classify similar activities in the future.'),
                value: _createRule,
                onChanged: (bool value) {
                  setState(() {
                    _createRule = value;
                  });
                },
              ),
              if (_createRule)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextFormField(
                    controller: _windowTitleContainsController,
                    decoration: const InputDecoration(
                      labelText: 'If window title contains...',
                      hintText: '(Optional, leave empty to match any)',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('Save for All (${widget.itemCount})'),
        ),
      ],
    );
  }
}