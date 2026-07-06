import 'package:flutter/material.dart';

Future<bool> showEditor(
  BuildContext context,
  String title,
  List<TextEditingController> controllers,
  List<String> labels,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < controllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(labelText: labels[i]),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ) ??
      false;
}
