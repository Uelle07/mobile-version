import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_member_app/features/member/profile/views/change_password_screen.dart';

void main() {
  Widget buildTestableWidget({Size screenSize = const Size(390, 844)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const ChangePasswordScreen(),
        ),
      ),
    );
  }

  group('ChangePasswordScreen Widget & UI Tests', () {
    testWidgets('renders all initial header, field, indicator, and button elements', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Change Password'), findsWidgets); // Header & button or title
      expect(
        find.text('Update your account credentials to keep your member account secure.'),
        findsOneWidget,
      );

      // Labels
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Placeholders
      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Create a new password (min. 8 characters)'), findsOneWidget);
      expect(find.text('Re-type your new password'), findsOneWidget);

      // Initial live criteria indicators
      expect(find.text('At least 8 characters in length'), findsOneWidget);
      expect(find.text('Passwords must match'), findsOneWidget);

      // Action buttons
      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dynamic live criteria indicator updates as user types new password', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final newPwdField = find.widgetWithText(TextField, 'Create a new password (min. 8 characters)');

      // Type 4 characters -> should show (4/8)
      await tester.enterText(newPwdField, 'pass');
      await tester.pump();
      expect(find.text('At least 8 characters in length (4/8)'), findsOneWidget);

      // Type 7 characters -> should show (7/8)
      await tester.enterText(newPwdField, 'pass123');
      await tester.pump();
      expect(find.text('At least 8 characters in length (7/8)'), findsOneWidget);

      // Type 8 characters -> should show without count
      await tester.enterText(newPwdField, 'pass1234');
      await tester.pump();
      expect(find.text('At least 8 characters in length'), findsOneWidget);
    });

    testWidgets('dynamic live match indicator updates correctly for match and mismatch', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final newPwdField = find.widgetWithText(TextField, 'Create a new password (min. 8 characters)');
      final confirmPwdField = find.widgetWithText(TextField, 'Re-type your new password');

      // Before new password reaches 8 characters, should show "Passwords must match"
      await tester.enterText(newPwdField, 'short');
      await tester.enterText(confirmPwdField, 'short');
      await tester.pump();
      expect(find.text('Passwords must match'), findsOneWidget);

      // New password is 8+ chars, but confirm password differs -> "Passwords do not match"
      await tester.enterText(newPwdField, 'ValidPass123');
      await tester.enterText(confirmPwdField, 'DifferentPass123');
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Confirm password matches -> "Passwords match"
      await tester.enterText(confirmPwdField, 'ValidPass123');
      await tester.pump();
      expect(find.text('Passwords match'), findsOneWidget);
    });

    testWidgets('password visibility toggle toggles obscureText state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Find eye icons
      final visibilityIcons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcons, findsNWidgets(3));

      // Tap first eye toggle (Current password)
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // Should now show 1 visibility_off_outlined icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    });

    testWidgets('validates empty current password on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Submit without typing anything
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Current password is required.'), findsOneWidget);
      expect(find.text('• Please enter your current password.'), findsOneWidget);
    });

    testWidgets('validates same new password as current password on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final currentField = find.widgetWithText(TextField, 'Enter your current password');
      final newPwdField = find.widgetWithText(TextField, 'Create a new password (min. 8 characters)');
      final confirmPwdField = find.widgetWithText(TextField, 'Re-type your new password');

      await tester.enterText(currentField, 'Password123');
      await tester.enterText(newPwdField, 'Password123');
      await tester.enterText(confirmPwdField, 'Password123');
      await tester.pump();

      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(
        find.text('New password cannot be the same as your current password.'),
        findsWidgets,
      );
    });

    testWidgets('validates empty or mismatched confirm password on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final currentField = find.widgetWithText(TextField, 'Enter your current password');
      final newPwdField = find.widgetWithText(TextField, 'Create a new password (min. 8 characters)');
      final confirmPwdField = find.widgetWithText(TextField, 'Re-type your new password');

      await tester.enterText(currentField, 'OldPassword123');
      await tester.enterText(newPwdField, 'NewPassword123');
      // Leave confirm empty
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Please confirm your new password.'), findsWidgets);

      // Now enter mismatched confirm
      await tester.enterText(confirmPwdField, 'WrongPassword123');
      await tester.pump();
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('New password and confirmation do not match.'), findsWidgets);
    });

    testWidgets('valid form shows confirmation dialog with required buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final currentField = find.widgetWithText(TextField, 'Enter your current password');
      final newPwdField = find.widgetWithText(TextField, 'Create a new password (min. 8 characters)');
      final confirmPwdField = find.widgetWithText(TextField, 'Re-type your new password');

      await tester.enterText(currentField, 'OldPassword123');
      await tester.enterText(newPwdField, 'NewSecretPassword123');
      await tester.enterText(confirmPwdField, 'NewSecretPassword123');
      await tester.pump();

      final updateBtn = find.text('Update Password');
      await tester.ensureVisible(updateBtn);
      await tester.pumpAndSettle();
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Check dialog appearance
      expect(find.text('Confirm Password Change'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to update your password? You will need to use this new password for your next login sessions.',
        ),
        findsOneWidget,
      );
      expect(find.text('Yes, Change Password'), findsOneWidget);
      expect(find.text('Cancel'), findsWidgets);

      // Verify no overflow occurred when dialog opened
      expect(tester.takeException(), isNull);

      // Dismiss dialog
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Password Change'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero-overflow verified across tight responsive mobile screen size', (tester) async {
      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        originalOnError?.call(details);
      };

      final testSizes = [
        const Size(320, 568), // Ultra-compact (iPhone SE 1st gen)
        const Size(360, 640), // Standard small Android
        const Size(390, 844), // Standard modern mobile
        const Size(412, 915), // Large Android phone
        const Size(600, 350), // Compact landscape mobile
      ];

      try {
        for (final size in testSizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(buildTestableWidget(screenSize: size));
          await tester.pumpAndSettle();

          final exception = tester.takeException();
          if (exception != null && errorDetails != null) {
            // ignore: avoid_print
            print('CRITICAL OVERFLOW ERROR DUMP:\n${errorDetails!.summary}\n${errorDetails!.informationCollector?.call().join('\n')}');
          }
          expect(exception, isNull, reason: 'Failed with overflow on screen size: $size');
        }
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
