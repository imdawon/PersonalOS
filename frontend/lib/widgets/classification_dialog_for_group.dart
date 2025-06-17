// frontend/lib/widgets/classification_dialog_for_group.dart
import 'package:flutter/material.dart';

class ClassificationDialogForGroup extends StatefulWidget {
  final String appName;
  final int itemCount;
  final Function(String userDefinedName, bool isHelpful, String goalContext) onSave;

  const ClassificationDialogForGroup({
    super.key,
    required this.appName,
    required this.itemCount,
    required this.onSave,
  });

  @override
  State<ClassificationDialogForGroup> createState() => _ClassificationDialogForGroupState();
}

class _ClassificationDialogForGroupState extends State<ClassificationDialogForGroup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isHelpful = true;
  String _goalContext = 'Work';

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
      widget.onSave(
        _nameController.text,
        _isHelpful,
        _goalContext,
      );
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