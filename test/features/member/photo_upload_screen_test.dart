import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_member_app/features/member/profile/views/photo_upload_screen.dart';
import 'package:cooperative_member_app/features/member/dashboard/providers/current_member_provider.dart';
import 'package:cooperative_member_app/core/models/member.dart';

void main() {
  Widget createTestWidget({Member? mockMember}) {
    return ProviderScope(
      overrides: [
        currentMemberProvider.overrideWith((ref) => Stream.value(mockMember)),
      ],
      child: const MaterialApp(
        home: PhotoUploadScreen(),
      ),
    );
  }

  group('PhotoUploadScreen Tests', () {
    testWidgets('renders all UI elements and conforms to responsive zero-overflow design',
        (tester) async {
      // Test with small mobile screen to verify zero-overflow
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final member = Member(
        id: 'member_123',
        accountNumber: 'ACC-001',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        photoUrl: 'sample_avatar.jpg',
      );

      await tester.pumpWidget(createTestWidget(mockMember: member));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Upload Profile Photo'), findsOneWidget);
      expect(
        find.text('Upload or replace your official 2x2 / passport-size member photo.'),
        findsOneWidget,
      );
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify Live Preview Section
      expect(find.text('Active Passport Photo on Record'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);

      // Verify Picker Controls
      expect(find.text('Take New Photo'), findsOneWidget);
      expect(find.text('Select from Gallery'), findsOneWidget);

      // Verify Guidance Text
      expect(
        find.text('Accepted formats: JPG, JPEG, PNG. Maximum file size: 2 MB.'),
        findsOneWidget,
      );

      // Verify Action Buttons
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Ensure no exceptions or overflows occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows validation error when uploading without selecting a photo',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify no error initially
      expect(find.text('Upload Failed:'), findsNothing);

      // Tap "Upload Photo"
      final uploadBtn = find.text('Upload Photo');
      expect(uploadBtn, findsOneWidget);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      // Verify Error Alert Banner is shown
      expect(find.text('Upload Failed:'), findsOneWidget);
      expect(
        find.text('Please select a photo file to proceed with your upload.'),
        findsOneWidget,
      );

      // Dismiss the error banner
      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Verify Error Alert Banner is dismissed
      expect(find.text('Upload Failed:'), findsNothing);
      expect(
        find.text('Please select a photo file to proceed with your upload.'),
        findsNothing,
      );
    });

    testWidgets('cancels and pops when Cancel button is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProviderScope(
                        child: PhotoUploadScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Profile Photo'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Back to initial screen
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Upload Profile Photo'), findsNothing);
    });
  });
}
