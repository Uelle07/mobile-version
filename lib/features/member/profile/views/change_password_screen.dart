import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/space_app_bar.dart';
import '../../dashboard/providers/current_member_provider.dart';

/// Screen allowing authenticated cooperative members to update their account password.
/// Matches member/change_password.php with strict zero-overflow responsive design,
/// live validation feedback, Firebase re-authentication, and security flag updates.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocusNode = FocusNode();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _topErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onCurrentChanged);
    _newPasswordController.addListener(_onNewOrConfirmChanged);
    _confirmPasswordController.addListener(_onNewOrConfirmChanged);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_onCurrentChanged);
    _newPasswordController.removeListener(_onNewOrConfirmChanged);
    _confirmPasswordController.removeListener(_onNewOrConfirmChanged);

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onCurrentChanged() {
    if (_currentError != null &&
        _currentPasswordController.text.trim().isNotEmpty) {
      setState(() {
        _currentError = null;
      });
    }
  }

  void _onNewOrConfirmChanged() {
    setState(() {
      final newPwd = _newPasswordController.text;
      final confirmPwd = _confirmPasswordController.text;

      if (_newError != null && newPwd.length >= 8) {
        _newError = null;
      }

      if (_confirmError != null &&
          confirmPwd.isNotEmpty &&
          newPwd == confirmPwd) {
        _confirmError = null;
      }
    });
  }

  void _validateCurrentPasswordInline() {
    final currentVal = _currentPasswordController.text.trim();
    setState(() {
      if (currentVal.isEmpty) {
        _currentError = 'Current password is required.';
      } else {
        _currentError = null;
      }
    });
  }

  void _validatePasswordInline() {
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    setState(() {
      if (newPwd.length >= 8) {
        _newError = null;
      } else if (newPwd.isNotEmpty) {
        _newError = 'New password must be at least 8 characters in length.';
      } else {
        _newError = null;
      }

      if (newPwd.length < 8) {
        _confirmError = null;
      } else if (confirmPwd.isEmpty) {
        _confirmError = null;
      } else if (newPwd == confirmPwd) {
        _confirmError = null;
      } else {
        _confirmError = 'New password and confirmation do not match.';
      }
    });
  }

  void _handleSubmit() {
    // Dismiss soft keyboard
    FocusScope.of(context).unfocus();

    final currentVal = _currentPasswordController.text.trim();
    final newVal = _newPasswordController.text;
    final confirmVal = _confirmPasswordController.text;

    setState(() {
      _topErrorMessage = null;
    });

    // 1. Current Password Validation
    if (currentVal.isEmpty) {
      setState(() {
        _currentError = 'Current password is required.';
        _topErrorMessage = 'Please enter your current password.';
      });
      _currentFocusNode.requestFocus();
      return;
    }

    // 2. New Password Minimum Length Validation
    if (newVal.length < 8) {
      setState(() {
        _newError = 'New password must be at least 8 characters in length.';
        _topErrorMessage =
            'New password must be at least 8 characters long.';
      });
      _newFocusNode.requestFocus();
      return;
    }

    // 3. New Password Different From Current Validation
    if (currentVal == newVal) {
      setState(() {
        _newError =
            'New password cannot be the same as your current password.';
        _topErrorMessage =
            'New password cannot be the same as your current password.';
      });
      _newFocusNode.requestFocus();
      return;
    }

    // 4. Confirm Password Empty Validation
    if (confirmVal.isEmpty) {
      setState(() {
        _confirmError = 'Please confirm your new password.';
        _topErrorMessage = 'Please confirm your new password.';
      });
      _confirmFocusNode.requestFocus();
      return;
    }

    // 5. Confirm Password Matching Validation
    if (newVal != confirmVal) {
      setState(() {
        _confirmError = 'New password and confirmation do not match.';
        _topErrorMessage =
            'New password and confirmation do not match.';
      });
      _confirmFocusNode.requestFocus();
      return;
    }

    // All validations passed -> Show Confirmation Dialog
    _showConfirmationDialog(currentVal, newVal);
  }

  Future<void> _showConfirmationDialog(
    String currentPassword,
    String newPassword,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF13172E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Password Change',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to update your password? You will need to use this new password for your next login sessions.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your session will remain authenticated, but your primary credentials will be updated immediately.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Yes, Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _executePasswordChange(currentPassword, newPassword);
    }
  }

  Future<void> _executePasswordChange(
    String currentPassword,
    String newPassword,
  ) async {
    setState(() {
      _isSubmitting = true;
      _topErrorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Determine email address for re-authentication
      final member = ref.read(currentMemberProvider).value;
      final email = user.email ??
          (member?.email != null && member!.email!.contains('@')
              ? member.email!
              : '${member?.accountNumber ?? "user"}@space.coop');

      // 1. Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update to new password
      await user.updatePassword(newPassword);

      // 3. Post-Update Account Flags in Firestore
      await FirebaseFirestore.instance
          .collection('member_account')
          .doc(user.uid)
          .set({
        'first_login': false,
        'password_changed': true,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // 4. Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Password changed successfully.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Return to Dashboard after a brief delay (1500ms matching web)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          GoRouter.of(context).go('/member');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      String errorMsg =
          'Failed to update password. Please check your connection and try again.';

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-mismatch') {
        errorMsg = 'Current password is incorrect.';
        setState(() {
          _currentError = 'Current password is incorrect.';
        });
        _currentFocusNode.requestFocus();
      } else if (e.code == 'weak-password') {
        errorMsg = 'The new password is too weak. Please choose a stronger password.';
        setState(() {
          _newError = errorMsg;
        });
        _newFocusNode.requestFocus();
      } else if (e.code == 'requires-recent-login') {
        errorMsg =
            'This operation is sensitive and requires recent login. Please log in again.';
      }

      setState(() {
        _topErrorMessage = errorMsg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _topErrorMessage =
            'Failed to update password. Please check your connection and try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _topErrorMessage ?? 'Failed to update password.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      resizeToAvoidBottomInset: true,
      appBar: const SpaceAppBar(),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Navigation Button (<- Dashboard)
                    _buildBackNavigationButton(),
                    const SizedBox(height: 16),

                    // Top Alert Banner (if error occurred)
                    if (_topErrorMessage != null) ...[
                      _buildTopAlertBanner(_topErrorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // Main Glassmorphism Card Container
                    _buildChangePasswordCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Back navigation button matching web portal's "<- Dashboard"
  Widget _buildBackNavigationButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/member');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top alert container matching web portal's alert-danger banner
  Widget _buildTopAlertBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF87171),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please correct the following errors:',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 3),
                Text(
                  '• $message',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _topErrorMessage = null),
          ),
        ],
      ),
    );
  }

  /// Main Card Container with Dark Glassmorphism Styling
  Widget _buildChangePasswordCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header: Purple Key Badge Icon, Title & Subtitle
          _buildCardHeader(),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 24),

          // Field 1: Current Password
          _buildCurrentPasswordField(),

          const SizedBox(height: 20),

          // Field 2: New Password
          _buildNewPasswordField(),

          const SizedBox(height: 20),

          // Field 3: Confirm New Password
          _buildConfirmPasswordField(),

          const SizedBox(height: 28),

          // Action Buttons: Update Password & Cancel with Row Protection
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Header with Purple Key Badge Icon (#8B5CF6), Title & Subtitle
  Widget _buildCardHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Purple Key Badge Container
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.vpn_key_rounded,
            color: Color(0xFF8B5CF6),
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        // Title & Subtitle
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                softWrap: true,
              ),
              SizedBox(height: 4),
              Text(
                'Update your account credentials to keep your member account secure.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.5,
                  height: 1.35,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Field A: Current Password
  Widget _buildCurrentPasswordField() {
    final hasError = _currentError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Lock Icon & Red Asterisk
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF00F2FE),
              size: 16,
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Current Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Text Field with Visibility Toggle
        TextField(
          controller: _currentPasswordController,
          focusNode: _currentFocusNode,
          obscureText: _obscureCurrent,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (_) => _validateCurrentPasswordInline(),
          decoration: InputDecoration(
            hintText: 'Enter your current password',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF00F2FE),
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : Colors.white.withValues(alpha: 0.15),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : const Color(0xFF00F2FE),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Inline Error Message
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFF87171),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _currentError!,
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Field B: New Password with Shield Icon & Live Criteria Indicator
  Widget _buildNewPasswordField() {
    final hasError = _newError != null;
    final newPwd = _newPasswordController.text;
    final isMinLength = newPwd.length >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Shield Icon & Red Asterisk
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: Color(0xFF8B5CF6),
              size: 16,
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'New Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Text Field with Visibility Toggle
        TextField(
          controller: _newPasswordController,
          focusNode: _newFocusNode,
          obscureText: _obscureNew,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (_) => _validatePasswordInline(),
          decoration: InputDecoration(
            hintText: 'Create a new password (min. 8 characters)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF00F2FE),
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureNew = !_obscureNew);
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : (isMinLength
                        ? const Color(0xFF34D399)
                        : Colors.white.withValues(alpha: 0.15)),
                width: (hasError || isMinLength) ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : const Color(0xFF8B5CF6),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Inline Error Message (if any)
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFF87171),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _newError!,
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Live Visual Criteria Indicator Box
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isMinLength
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: isMinLength
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isMinLength
                    ? 'At least 8 characters in length'
                    : (newPwd.isNotEmpty
                        ? 'At least 8 characters in length (${newPwd.length}/8)'
                        : 'At least 8 characters in length'),
                style: TextStyle(
                  color: isMinLength
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Field C: Confirm New Password with Check-Double Icon & Live Match Indicator
  Widget _buildConfirmPasswordField() {
    final hasError = _confirmError != null;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    final isNewValid = newPwd.length >= 8;
    final isFilled = confirmPwd.isNotEmpty;
    final isMatch = isNewValid && isFilled && (newPwd == confirmPwd);
    final isMismatch = isNewValid && isFilled && (newPwd != confirmPwd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with Check-Double Icon & Red Asterisk
        Row(
          children: [
            const Icon(
              Icons.done_all_rounded,
              color: Color(0xFF00F2FE),
              size: 16,
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Confirm New Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Text Field with Visibility Toggle
        TextField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocusNode,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (_) => _validatePasswordInline(),
          decoration: InputDecoration(
            hintText: 'Re-type your new password',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF00F2FE),
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : (isMatch
                        ? const Color(0xFF34D399)
                        : Colors.white.withValues(alpha: 0.15)),
                width: (hasError || isMatch) ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : const Color(0xFF00F2FE),
                width: 1.5,
              ),
            ),
          ),
        ),

        // Inline Error Message (if any)
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFF87171),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _confirmError!,
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Live Match Indicator
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isMatch
                  ? Icons.check_circle_rounded
                  : (isMismatch
                      ? Icons.cancel_rounded
                      : Icons.info_outline_rounded),
              color: isMatch
                  ? const Color(0xFF34D399)
                  : (isMismatch
                      ? const Color(0xFFF87171)
                      : Colors.white54),
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isMatch
                    ? 'Passwords match'
                    : (isMismatch
                        ? 'Passwords do not match'
                        : 'Passwords must match'),
                style: TextStyle(
                  color: isMatch
                      ? const Color(0xFF34D399)
                      : (isMismatch
                          ? const Color(0xFFF87171)
                          : Colors.white54),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Action Buttons ("Update Password" & "Cancel") with Mandatory Button Row Protection:
  /// Expanded(flex: 3, child: updatePasswordButton) and Expanded(flex: 2, child: cancelButton)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Update Password Button (flex: 3)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: _isSubmitting
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isSubmitting ? Colors.grey[800] : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isSubmitting
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isSubmitting ? 'Updating...' : 'Update Password',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Cancel Button (flex: 2)
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      GoRouter.of(context).go('/member');
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white70,
                ),
                softWrap: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
