import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  int _currentStep = 0;

  final _personalFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Member')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // TODO: Submit the entire form to Firestore
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: const Text('Personal'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _personalFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Account Number'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Date of Birth'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Civil Status'),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Contact'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _contactFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email Address'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Present Address'),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Employment'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _employmentFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Employer Name'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Job Title'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
