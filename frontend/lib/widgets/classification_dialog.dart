import 'package:flutter/material.dart';
import 'package:PersonalOS/models/activity_session.dart';
import 'package:PersonalOS/models/classification_request.dart';
import 'package:PersonalOS/providers/activity_provider.dart';
import 'package:provider/provider.dart';

class ClassificationDialog extends StatefulWidget {
  final ActivitySession session;
  const ClassificationDialog({super.key, required this.session});

  @override
  State<ClassificationDialog> createState() => _ClassificationDialogState();
}

class _ClassificationDialogState extends State<ClassificationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isHelpful = true;
  String _goalContext = 'Work'; // Default value

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final request = ClassificationRequest(
        appName: widget.session.appName,
        windowTitle: widget.session.windowTitle,
        userDefinedName: _nameController.text,
        isHelpful: _isHelpful,
        goalContext: _goalContext,
      );

      Provider.of<ActivityProvider>(context, listen: false).classify(request);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Classify Activity'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Activity Name (e.g., Programming)'),
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
                items: ['Work', 'Learn', 'Relax', 'Personal', 'Wasting Time']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}