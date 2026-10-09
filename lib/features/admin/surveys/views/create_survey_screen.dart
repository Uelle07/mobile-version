import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_member_app/core/widgets/space_app_bar.dart';

class CreateSurveyScreen extends ConsumerStatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SpaceAppBar(title: const Text('Create Survey')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: add survey to repository
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Survey'),
            ),
          ],
        ),
      ),
    );
  }
}
