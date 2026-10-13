import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooperative_member_app/core/widgets/space_app_bar.dart';
import 'package:cooperative_member_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../providers/member_provider.dart';

class _ChildFormEntry {
  final GlobalKey fieldKey = GlobalKey();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String extensionName = '';
  DateTime? birthday;

  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    birthdayController.dispose();
  }
}

/// Auto-hyphenates mobile digits as `09XX-XXX-XXXX` (max 11 digits)
/// or `9XX-XXX-XXXX` (max 10 digits).
class _PhoneHyphenInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final startsWithZero = digitsOnly.startsWith('0');
    final maxLen = startsWithZero ? 11 : 10;
    final clipped = digitsOnly.length > maxLen
        ? digitsOnly.substring(0, maxLen)
        : digitsOnly;

    final buffer = StringBuffer();
    if (startsWithZero) {
      // Format: 09XX-XXX-XXXX (4 - 3 - 4)
      for (int i = 0; i < clipped.length; i++) {
        if (i == 4 || i == 7) buffer.write('-');
        buffer.write(clipped[i]);
      }
    } else {
      // Format: 9XX-XXX-XXXX (3 - 3 - 4)
      for (int i = 0; i < clipped.length; i++) {
        if (i == 3 || i == 6) buffer.write('-');
        buffer.write(clipped[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Section keys for auto-scrolling to first invalid field
  final _personalSectionKey = GlobalKey();
  final _contactSectionKey = GlobalKey();
  final _parentsSectionKey = GlobalKey();
  final _spouseSectionKey = GlobalKey();
  final _childrenSectionKey = GlobalKey();
  final _referencesSectionKey = GlobalKey();

  // Auto-generated account number preview
  String _accountNumber = '2026-${1000 + Random().nextInt(9000)}';

  // Section 1: Passport Photo (Optional, max 5 MB, JPG/JPEG/PNG)
  Uint8List? _passportPhotoBytes;
  String? _passportPhotoDataUrl;
  String? _passportPhotoName;
  String? _passportPhotoError;

  // Section 2: Personal Information
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _extensionName = '';
  String? _sex;
  String _civilStatus = 'Single';
  DateTime? _birthday;
  final _birthdayController = TextEditingController();
  String _nationality = 'Filipino';

  // Section 3: Contact & Employment Information
  String _countryCode = '+63';
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _employerController = TextEditingController();
  final _employerAddressController = TextEditingController();
  final _homeAddressController = TextEditingController();

  // Section 4: Parents Information (Optional)
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();

  // Section 5: Spouse Information (Conditional on Civil Status == 'Married')
  final _spouseFirstNameController = TextEditingController();
  final _spouseMiddleNameController = TextEditingController();
  final _spouseLastNameController = TextEditingController();
  String _spouseExtension = '';
  final _spouseOccupationController = TextEditingController();
  final _spouseEmployerController = TextEditingController();

  // Section 6: Children Information (Dynamic List - Optional)
  final List<_ChildFormEntry> _children = [];

  // Section 7: Character References (Optional)
  final _ref1Controller = TextEditingController();
  final _ref2Controller = TextEditingController();

  // Section 8: Member Signature (Optional, max 2 MB, JPG/PNG or Drawn)
  Uint8List? _signatureBytes;
  String? _signatureDataUrl;
  String? _signatureName;
  String? _signatureError;

  // Submission & validation state
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;
  String? _topErrorSummary;

  static const int _maxPhotoBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxSignatureBytes = 2 * 1024 * 1024; // 2 MB

  static const Color _bgDeepNavy = Color(0xFF0B132B);
  static const Color _bgDarkNavy = Color(0xFF1C2541);
  static const Color _inputFill = Color(0x990F172A); // rgba(15, 23, 42, 0.6)
  static const Color _cyanAccent = Color(0xFF00C2A8);
  static const Color _errorRed = Color(0xFFEF4444);

  static const List<String> _suffixOptions = [
    '',
    'Jr.',
    'Sr.',
    'II',
    'III',
    'IV',
    'V',
  ];

  static const List<String> _civilStatusOptions = [
    'Single',
    'Married',
    'Widowed',
    'Separated',
    'Divorced',
  ];

  static const List<String> _nationalityOptions = [
    'Filipino',
    'American',
    'Australian',
    'British',
    'Canadian',
    'Chinese',
    'German',
    'Indian',
    'Indonesian',
    'Italian',
    'Japanese',
    'Korean',
    'Malaysian',
    'Singaporean',
    'Spanish',
    'Thai',
    'Vietnamese',
    'Other',
  ];

  static const List<Map<String, String>> _countryCodeOptions = [
    {'code': '+63', 'label': '+63 (PH)'},
    {'code': '+1', 'label': '+1 (US)'},
    {'code': '+44', 'label': '+44 (UK)'},
    {'code': '+61', 'label': '+61 (AU)'},
    {'code': '+65', 'label': '+65 (SG)'},
    {'code': '+81', 'label': '+81 (JP)'},
    {'code': '+971', 'label': '+971 (AE)'},
  ];

  @override
  void initState() {
    super.initState();
    _accountNumber = _generateAccountNumber();
  }

  String _generateAccountNumber() {
    final rand = 1000 + Random().nextInt(9000);
    return '2026-$rand';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _employerController.dispose();
    _employerAddressController.dispose();
    _homeAddressController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _spouseFirstNameController.dispose();
    _spouseMiddleNameController.dispose();
    _spouseLastNameController.dispose();
    _spouseOccupationController.dispose();
    _spouseEmployerController.dispose();
    _ref1Controller.dispose();
    _ref2Controller.dispose();
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  void _clearSpouseFields() {
    _spouseFirstNameController.clear();
    _spouseMiddleNameController.clear();
    _spouseLastNameController.clear();
    _spouseExtension = '';
    _spouseOccupationController.clear();
    _spouseEmployerController.clear();
  }

  // ===========================================================================
  // VALIDATORS
  // ===========================================================================

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
  static final RegExp _optionalNameRegex = RegExp(r"^[a-zA-Z\s\-'\.]*$");
  static final RegExp _occupationRegex = RegExp(r"^[a-zA-Z\s\-\./']+$");
  static final RegExp _emailRegex = RegExp(
    r'^(?!\d+@)[^\s_]+@[^\s_]+\.com$',
    caseSensitive: false,
  );

  String? _validateFirstName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'First Name is required.';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'First Name cannot contain numbers or special characters.';
    }
    return null;
  }

  String? _validateMiddleName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!_optionalNameRegex.hasMatch(trimmed)) {
      return 'Middle Name may only contain letters, spaces, hyphens, and periods.';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Last Name is required.';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Last Name cannot contain numbers or special characters.';
    }
    return null;
  }

  String? _validateSex(String? value) {
    if (value == null || (value != 'Male' && value != 'Female')) {
      return 'Please select Sex.';
    }
    return null;
  }

  String? _validateCivilStatus(String? value) {
    if (value == null || !_civilStatusOptions.contains(value)) {
      return 'Please select a valid Civil Status.';
    }
    return null;
  }

  String? _validateBirthday(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || _birthday == null) {
      return 'Birthday is required.';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (_birthday!.isAfter(today)) {
      return 'Birthday cannot be a future date.';
    }
    if (_birthday!.isBefore(DateTime(1900, 1, 1))) {
      return 'Birthday must be after January 1, 1900.';
    }
    return null;
  }

  String? _validateNationality(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nationality is required.';
    }
    return null;
  }

  String? _validateContactNumber(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Contact number is required.';
    }
    final digitsOnly = trimmed.replaceAll('-', '').replaceAll(' ', '');
    if (!RegExp(r'^\d{10,11}$').hasMatch(digitsOnly)) {
      return 'Please enter a valid 10 or 11-digit mobile number.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Email Address is required.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Invalid Email Address. Underscores are not allowed, prefix cannot be numbers only, and it must end with .com.';
    }
    return null;
  }

  String? _validateOccupation(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Occupation is required.';
    }
    if (!_occupationRegex.hasMatch(trimmed)) {
      return 'Occupation contains invalid characters.';
    }
    return null;
  }

  String? _validateHomeAddress(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Home Address is required.';
    }
    return null;
  }

  String? _validateFatherName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return "Father's name cannot contain numbers.";
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return "Father's name may only contain letters, spaces, hyphens, and periods.";
    }
    return null;
  }

  String? _validateMotherName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return "Mother's name cannot contain numbers.";
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return "Mother's name may only contain letters, spaces, hyphens, and periods.";
    }
    return null;
  }

  String? _validateSpouseFirstName(String? value) {
    if (_civilStatus != 'Married') return null;
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Spouse First Name is required for married members.';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Spouse First Name cannot contain numbers or special characters.';
    }
    return null;
  }

  String? _validateSpouseMiddleName(String? value) {
    if (_civilStatus != 'Married') return null;
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Spouse Middle Name may only contain letters, spaces, hyphens, and periods.';
    }
    return null;
  }

  String? _validateSpouseLastName(String? value) {
    if (_civilStatus != 'Married') return null;
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Spouse Last Name is required for married members.';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Spouse Last Name cannot contain numbers or special characters.';
    }
    return null;
  }

  String? _validateChildFirstName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return "Child's first name is required.";
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return "Child's first name cannot contain numbers or special characters.";
    }
    return null;
  }

  String? _validateChildMiddleName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!_nameRegex.hasMatch(trimmed)) {
      return "Child's middle name may only contain letters, spaces, hyphens, and periods.";
    }
    return null;
  }

  String? _validateChildLastName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return "Child's last name is required.";
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return "Child's last name cannot contain numbers or special characters.";
    }
    return null;
  }

  String? _validateChildBirthday(_ChildFormEntry entry) {
    if (entry.birthday == null || entry.birthdayController.text.trim().isEmpty) {
      return "Child's date of birth is required.";
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (entry.birthday!.isAfter(today)) {
      return 'Birthday cannot be a future date.';
    }
    if (entry.birthday!.isBefore(DateTime(1900, 1, 1))) {
      return 'Birthday must be after January 1, 1900.';
    }
    return null;
  }

  String? _validateReferenceName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Reference name may only contain letters, spaces, hyphens, and periods.';
    }
    return null;
  }

  // ===========================================================================
  // PICKERS (PHOTO, SIGNATURE, DATES)
  // ===========================================================================

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _bgDarkNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Attach Passport Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _cyanAccent),
                title: const Text(
                  'Take Photo (Camera)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _cyanAccent),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickPassportPhoto(source);
    }
  }

  Future<void> _pickPassportPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;

      final name = picked.name.toLowerCase();
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        setState(() {
          _passportPhotoError = 'Accepted formats: JPG, JPEG, PNG only.';
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        setState(() {
          _passportPhotoError = 'Photo image must be 5 MB or smaller.';
        });
        return;
      }

      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      setState(() {
        _passportPhotoBytes = bytes;
        _passportPhotoDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        _passportPhotoName = picked.name;
        _passportPhotoError = null;
      });
    } catch (e) {
      setState(() {
        _passportPhotoError = 'Failed to attach photo: $e';
      });
    }
  }

  Future<void> _pickSignaturePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 90,
      );
      if (picked == null) return;

      final name = picked.name.toLowerCase();
      final ext = name.contains('.') ? name.split('.').last : 'png';
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        setState(() {
          _signatureError = 'Accepted formats: JPG or PNG only.';
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxSignatureBytes) {
        setState(() {
          _signatureError = 'Signature image must be 2 MB or smaller.';
        });
        return;
      }

      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      setState(() {
        _signatureBytes = bytes;
        _signatureDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        _signatureName = picked.name;
        _signatureError = null;
      });
    } catch (e) {
      setState(() {
        _signatureError = 'Failed to upload signature: $e';
      });
    }
  }

  Future<void> _openSignaturePadDialog() async {
    final resultBytes = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => const _SignaturePadDialog(),
    );

    if (resultBytes != null) {
      if (resultBytes.lengthInBytes > _maxSignatureBytes) {
        setState(() {
          _signatureError = 'Signature image must be 2 MB or smaller.';
        });
        return;
      }
      setState(() {
        _signatureBytes = resultBytes;
        _signatureDataUrl =
            'data:image/png;base64,${base64Encode(resultBytes)}';
        _signatureName = 'drawn_signature.png';
        _signatureError = null;
      });
    }
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _cyanAccent,
              onPrimary: _bgDeepNavy,
              surface: _bgDarkNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectChildBirthday(int index) async {
    final now = DateTime.now();
    final entry = _children[index];
    final initial =
        entry.birthday ?? DateTime(now.year - 10, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _cyanAccent,
              onPrimary: _bgDeepNavy,
              surface: _bgDarkNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        entry.birthday = picked;
        entry.birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addChildCard() {
    setState(() {
      _children.add(_ChildFormEntry());
    });
  }

  void _removeChildCard(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  // ===========================================================================
  // VALIDATION, CONFIRMATION & SUBMISSION
  // ===========================================================================

  GlobalKey? _findFirstInvalidSectionKey() {
    if (_validateFirstName(_firstNameController.text) != null ||
        _validateMiddleName(_middleNameController.text) != null ||
        _validateLastName(_lastNameController.text) != null ||
        _validateSex(_sex) != null ||
        _validateCivilStatus(_civilStatus) != null ||
        _validateBirthday(_birthdayController.text) != null ||
        _validateNationality(_nationality) != null) {
      return _personalSectionKey;
    }

    if (_validateContactNumber(_contactController.text) != null ||
        _validateEmail(_emailController.text) != null ||
        _validateOccupation(_occupationController.text) != null ||
        _validateHomeAddress(_homeAddressController.text) != null) {
      return _contactSectionKey;
    }

    if (_validateFatherName(_fatherNameController.text) != null ||
        _validateMotherName(_motherNameController.text) != null) {
      return _parentsSectionKey;
    }

    if (_civilStatus == 'Married') {
      if (_validateSpouseFirstName(_spouseFirstNameController.text) != null ||
          _validateSpouseMiddleName(_spouseMiddleNameController.text) != null ||
          _validateSpouseLastName(_spouseLastNameController.text) != null) {
        return _spouseSectionKey;
      }
    }

    for (final child in _children) {
      if (_validateChildFirstName(child.firstNameController.text) != null ||
          _validateChildMiddleName(child.middleNameController.text) != null ||
          _validateChildLastName(child.lastNameController.text) != null ||
          _validateChildBirthday(child) != null) {
        return child.fieldKey;
      }
    }

    if (_validateReferenceName(_ref1Controller.text) != null ||
        _validateReferenceName(_ref2Controller.text) != null) {
      return _referencesSectionKey;
    }

    return null;
  }

  Future<void> _onRegisterTap() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasAttemptedSubmit = true;
      _topErrorSummary = null;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasMediaError =
        _passportPhotoError != null || _signatureError != null;

    if (!isFormValid || hasMediaError) {
      setState(() {
        _topErrorSummary =
            'Please fix the highlighted errors below before registering the member.';
      });

      final targetKey = _findFirstInvalidSectionKey();
      if (targetKey?.currentContext != null) {
        await Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      } else if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgDarkNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _cyanAccent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Confirm Registration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to register this new member record? A unique Member Account ID will be generated and credentials prepared.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyanAccent,
              foregroundColor: _bgDeepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Yes, Register Member',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitToFirestore();
    }
  }

  String _joinNameParts(List<String> parts) {
    return parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' ');
  }

  Future<void> _submitToFirestore() async {
    setState(() {
      _isSubmitting = true;
      _topErrorSummary = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final accountNumber = _accountNumber;

      final employer = _employerController.text.trim().isEmpty
          ? 'Not Specified'
          : _employerController.text.trim();
      final employerAddress = _employerAddressController.text.trim().isEmpty
          ? 'Not Specified'
          : _employerAddressController.text.trim();
      final fatherName = _fatherNameController.text.trim().isEmpty
          ? 'Not Specified'
          : _fatherNameController.text.trim();
      final motherName = _motherNameController.text.trim().isEmpty
          ? 'Not Specified'
          : _motherNameController.text.trim();

      String spouseName = 'Not Specified';
      String spouseOccupation = 'Not Specified';
      String spouseEmployer = 'Not Specified';

      if (_civilStatus == 'Married') {
        final joinedSpouse = _joinNameParts([
          _spouseFirstNameController.text,
          _spouseMiddleNameController.text,
          _spouseLastNameController.text,
          _spouseExtension,
        ]);
        spouseName = joinedSpouse.isEmpty ? 'Not Specified' : joinedSpouse;
        spouseOccupation = _spouseOccupationController.text.trim().isEmpty
            ? 'Not Specified'
            : _spouseOccupationController.text.trim();
        spouseEmployer = _spouseEmployerController.text.trim().isEmpty
            ? 'Not Specified'
            : _spouseEmployerController.text.trim();
      }

      final childrenList = _children.map((c) {
        final fullChildName = _joinNameParts([
          c.firstNameController.text,
          c.middleNameController.text,
          c.lastNameController.text,
          c.extensionName,
        ]);
        final bdayStr = c.birthday != null
            ? DateFormat('yyyy-MM-dd').format(c.birthday!)
            : c.birthdayController.text.trim();
        return <String, dynamic>{
          'name': fullChildName,
          'birthday': bdayStr,
        };
      }).toList();

      final referencesList = <Map<String, dynamic>>[];
      if (_ref1Controller.text.trim().isNotEmpty) {
        referencesList.add({'name': _ref1Controller.text.trim()});
      }
      if (_ref2Controller.text.trim().isNotEmpty) {
        referencesList.add({'name': _ref2Controller.text.trim()});
      }

      // Provision Firebase Auth credentials via secondary app so Admin stays logged in
      String? provisionedUid;
      try {
        FirebaseApp secondaryApp;
        try {
          secondaryApp = Firebase.app('MemberProvisionApp');
        } catch (_) {
          secondaryApp = await Firebase.initializeApp(
            name: 'MemberProvisionApp',
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: '$accountNumber@space.coop',
          password: accountNumber,
        );
        provisionedUid = cred.user?.uid;
        await secondaryAuth.signOut();
      } catch (_) {}

      final docRef = provisionedUid != null
          ? firestore.collection('member').doc(provisionedUid)
          : firestore.collection('member').doc();

      final payload = <String, dynamic>{
        'member_id': docRef.id,
        'account_number': accountNumber,
        'firstname': _firstNameController.text.trim(),
        'middlename': _middleNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'extension_name': _extensionName,
        'sex': _sex ?? 'Male',
        'nationality': _nationality,
        'civil_status': _civilStatus,
        'birthday': _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : _birthdayController.text.trim(),
        'contact_number': '$_countryCode ${_contactController.text.trim()}',
        'email': _emailController.text.trim(),
        'address': _homeAddressController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'employer': employer,
        'employer_address': employerAddress,
        'father_name': fatherName,
        'mother_name': motherName,
        'spouse_name': spouseName,
        'spouse_occupation': spouseOccupation,
        'spouse_employer': spouseEmployer,
        'children': childrenList,
        'references': referencesList,
        'passport_photo': _passportPhotoDataUrl,
        'signature': _signatureDataUrl,
        'signature_photo': _signatureDataUrl,
        'account_status': 'Active',
        'created_at': FieldValue.serverTimestamp(),
        'registeredAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(payload, SetOptions(merge: true));

      await firestore.collection('member_account').doc(docRef.id).set({
        'member_id': docRef.id,
        'account_number': accountNumber,
        'first_login': true,
        'password_changed': false,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Sync auxiliary collections for full cross-screen compatibility
      try {
        await firestore.collection('parents').add({
          'member_id': docRef.id,
          'father_name': fatherName,
          'mother_name': motherName,
        });

        if (_civilStatus == 'Married') {
          await firestore.collection('spouse').add({
            'member_id': docRef.id,
            'spouse_name': spouseName,
            'occupation': spouseOccupation,
            'employer': spouseEmployer,
          });
        }

        for (final child in childrenList) {
          await firestore.collection('children').add({
            'member_id': docRef.id,
            'child_name': child['name'],
            'birthday': child['birthday'],
          });
        }

        for (final refItem in referencesList) {
          await firestore.collection('member_references').add({
            'member_id': docRef.id,
            'reference_member_name': refItem['name'],
          });
        }
      } catch (_) {}

      ref.invalidate(membersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Successfully added member account: $accountNumber',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topErrorSummary = 'Failed to register member: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeepNavy,
      resizeToAvoidBottomInset: true,
      appBar: SpaceAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgDeepNavy, _bgDarkNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _hasAttemptedSubmit
                      ? AutovalidateMode.always
                      : AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAccountBadgeBanner(),
                      if (_topErrorSummary != null) ...[
                        const SizedBox(height: 16),
                        _buildTopErrorBanner(_topErrorSummary!),
                      ],
                      const SizedBox(height: 18),
                      _buildPassportPhotoSection(),
                      const SizedBox(height: 18),
                      _buildPersonalInformationSection(),
                      const SizedBox(height: 18),
                      _buildContactAndEmploymentSection(),
                      const SizedBox(height: 18),
                      _buildParentsInformationSection(),
                      if (_civilStatus == 'Married') ...[
                        const SizedBox(height: 18),
                        _buildSpouseInformationSection(),
                      ],
                      const SizedBox(height: 18),
                      _buildChildrenInformationSection(),
                      const SizedBox(height: 18),
                      _buildCharacterReferencesSection(),
                      const SizedBox(height: 18),
                      _buildSignatureSection(),
                      const SizedBox(height: 24),
                      _buildBottomActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountBadgeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cyanAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_outlined, color: _cyanAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AUTO-GENERATED ACCOUNT ID',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Auto-Generated Account ID: $_accountNumber',
                  style: const TextStyle(
                    color: _cyanAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Regenerate ID Preview',
            onPressed: _isSubmitting
                ? null
                : () => setState(() {
                      _accountNumber = _generateAccountNumber();
                    }),
            icon: const Icon(Icons.refresh, color: _cyanAccent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTopErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _errorRed.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: _errorRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _topErrorSummary = null),
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: PASSPORT PHOTO (OPTIONAL)
  // ---------------------------------------------------------------------------
  Widget _buildPassportPhotoSection() {
    return _buildSectionCard(
      title: 'Passport Photo (Optional)',
      icon: Icons.camera_alt_outlined,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isSubmitting ? null : _showPhotoSourceSheet,
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: _passportPhotoError != null ? _errorRed : _cyanAccent,
                    strokeWidth: 2,
                    borderRadius: 14,
                  ),
                  child: Container(
                    width: 140,
                    height: 160,
                    decoration: BoxDecoration(
                      color: _inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _passportPhotoBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _passportPhotoBytes!,
                              width: 140,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: _cyanAccent,
                                size: 38,
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '2x2 Passport Preview',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _showPhotoSourceSheet,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Attach Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cyanAccent,
                      side: const BorderSide(color: _cyanAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_passportPhotoBytes != null)
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                                _passportPhotoBytes = null;
                                _passportPhotoDataUrl = null;
                                _passportPhotoName = null;
                                _passportPhotoError = null;
                              }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _errorRed,
                        side: const BorderSide(color: _errorRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
              if (_passportPhotoName != null) ...[
                const SizedBox(height: 6),
                Text(
                  _passportPhotoName!,
                  style: const TextStyle(color: _cyanAccent, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Accepted formats: JPG, JPEG, PNG · Max 5 MB (recommended <= 2 MB)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
              if (_passportPhotoError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _passportPhotoError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: PERSONAL INFORMATION
  // ---------------------------------------------------------------------------
  Widget _buildPersonalInformationSection() {
    return Container(
      key: _personalSectionKey,
      child: _buildSectionCard(
        title: 'Personal Information',
        icon: Icons.person_outline,
        children: [
          _buildGlassTextField(
            controller: _firstNameController,
            label: 'First Name',
            isRequired: true,
            hintText: 'Enter first name',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateFirstName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _middleNameController,
            label: 'Middle Name',
            isRequired: false,
            hintText: 'Enter middle name (optional)',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateMiddleName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _lastNameController,
            label: 'Last Name',
            isRequired: true,
            hintText: 'Enter last name',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateLastName,
          ),
          const SizedBox(height: 14),
          _buildGlassDropdown<String>(
            label: 'Ext. (Suffix)',
            isRequired: false,
            value: _extensionName,
            items: _suffixOptions
                .map(
                  (ext) => DropdownMenuItem<String>(
                    value: ext,
                    child: Text(ext.isEmpty ? 'None' : ext),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _extensionName = val ?? ''),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGlassDropdown<String>(
                  label: 'Sex',
                  isRequired: true,
                  value: _sex,
                  hintText: 'Select Sex',
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  validator: _validateSex,
                  onChanged: (val) => setState(() => _sex = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassDropdown<String>(
                  label: 'Civil Status',
                  isRequired: true,
                  value: _civilStatus,
                  items: _civilStatusOptions
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  validator: _validateCivilStatus,
                  onChanged: (val) {
                    final newStatus = val ?? 'Single';
                    setState(() {
                      _civilStatus = newStatus;
                      if (newStatus != 'Married') {
                        _clearSpouseFields();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGlassDatePickerField(
            controller: _birthdayController,
            label: 'Birthday (Date of Birth)',
            isRequired: true,
            hintText: 'YYYY-MM-DD',
            onTap: _selectBirthday,
            validator: _validateBirthday,
          ),
          const SizedBox(height: 14),
          _buildGlassDropdown<String>(
            label: 'Nationality',
            isRequired: true,
            value: _nationality,
            items: _nationalityOptions
                .map(
                  (nat) => DropdownMenuItem<String>(
                    value: nat,
                    child: Text(nat),
                  ),
                )
                .toList(),
            validator: _validateNationality,
            onChanged: (val) =>
                setState(() => _nationality = val ?? 'Filipino'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: CONTACT & EMPLOYMENT INFORMATION
  // ---------------------------------------------------------------------------
  Widget _buildContactAndEmploymentSection() {
    return Container(
      key: _contactSectionKey,
      child: _buildSectionCard(
        title: 'Contact & Employment Information',
        icon: Icons.contact_phone_outlined,
        children: [
          _buildFieldLabel('Contact Number', isRequired: true),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _countryCode,
                  isExpanded: true,
                  dropdownColor: _bgDarkNavy,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: _glassInputDecoration(),
                  items: _countryCodeOptions
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text(
                            c['label']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _countryCode = val ?? '+63'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  inputFormatters: [_PhoneHyphenInputFormatter()],
                  validator: _validateContactNumber,
                  decoration: _glassInputDecoration(
                    hintText: '09XX-XXX-XXXX',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _emailController,
            label: 'Email Address',
            isRequired: true,
            hintText: 'member@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _occupationController,
            label: 'Occupation',
            isRequired: true,
            hintText: 'Enter occupation or profession',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            prefixIcon: Icons.work_outline,
            validator: _validateOccupation,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _employerController,
            label: 'Employer / Business Name',
            isRequired: false,
            hintText: 'Optional (defaults to Not Specified)',
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _employerAddressController,
            label: 'Employer Address',
            isRequired: false,
            hintText: 'Optional (defaults to Not Specified)',
            maxLength: 255,
            prefixIcon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _homeAddressController,
            label: 'Home Address',
            isRequired: true,
            hintText: 'House No., Street, Barangay, City, Province',
            maxLines: 3,
            maxLength: 255,
            prefixIcon: Icons.home_outlined,
            validator: _validateHomeAddress,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: PARENTS INFORMATION (OPTIONAL)
  // ---------------------------------------------------------------------------
  Widget _buildParentsInformationSection() {
    return Container(
      key: _parentsSectionKey,
      child: _buildSectionCard(
        title: 'Parents Information (Optional)',
        icon: Icons.family_restroom_outlined,
        children: [
          _buildGlassTextField(
            controller: _fatherNameController,
            label: "Father's Full Name",
            isRequired: false,
            hintText: "Enter father's full name",
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            validator: _validateFatherName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _motherNameController,
            label: "Mother's Full Name",
            isRequired: false,
            hintText: "Enter mother's full/maiden name",
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            validator: _validateMotherName,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 5: SPOUSE INFORMATION (CONDITIONAL ON MARRIED)
  // ---------------------------------------------------------------------------
  Widget _buildSpouseInformationSection() {
    return Container(
      key: _spouseSectionKey,
      child: _buildSectionCard(
        title: 'Spouse Information',
        icon: Icons.favorite_border,
        children: [
          _buildGlassTextField(
            controller: _spouseFirstNameController,
            label: 'Spouse First Name',
            isRequired: true,
            hintText: "Enter spouse's first name",
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateSpouseFirstName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _spouseMiddleNameController,
            label: 'Spouse Middle Name',
            isRequired: false,
            hintText: "Enter spouse's middle name (optional)",
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateSpouseMiddleName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _spouseLastNameController,
            label: 'Spouse Last Name',
            isRequired: true,
            hintText: "Enter spouse's last name",
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _validateSpouseLastName,
          ),
          const SizedBox(height: 14),
          _buildGlassDropdown<String>(
            label: 'Spouse Ext',
            isRequired: false,
            value: _spouseExtension,
            items: _suffixOptions
                .map(
                  (ext) => DropdownMenuItem<String>(
                    value: ext,
                    child: Text(ext.isEmpty ? 'None' : ext),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _spouseExtension = val ?? ''),
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _spouseOccupationController,
            label: 'Spouse Occupation',
            isRequired: false,
            hintText: 'Optional',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _spouseEmployerController,
            label: 'Spouse Employer',
            isRequired: false,
            hintText: 'Optional',
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: CHILDREN INFORMATION (DYNAMIC LIST — OPTIONAL)
  // ---------------------------------------------------------------------------
  Widget _buildChildrenInformationSection() {
    return Container(
      key: _childrenSectionKey,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.child_care_outlined, color: _cyanAccent, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Children Information (Optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _addChildCard,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Add Child'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cyanAccent,
                  side: const BorderSide(color: _cyanAccent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          if (_children.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Text(
                'No children added. Tap "+ Add Child" to include dependent children.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ),
          ...List.generate(_children.length, (index) {
            final child = _children[index];
            return Container(
              key: child.fieldKey,
              margin: EdgeInsets.only(
                bottom: index == _children.length - 1 ? 0 : 16,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _cyanAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Child #${index + 1}',
                        style: const TextStyle(
                          color: _cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove Child',
                        onPressed: _isSubmitting
                            ? null
                            : () => _removeChildCard(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: _errorRed,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: child.firstNameController,
                    label: 'Child First Name',
                    isRequired: true,
                    hintText: "Enter child's first name",
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    validator: _validateChildFirstName,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: child.middleNameController,
                    label: 'Child Middle Name',
                    isRequired: false,
                    hintText: "Enter child's middle name (optional)",
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    validator: _validateChildMiddleName,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: child.lastNameController,
                    label: 'Child Last Name',
                    isRequired: true,
                    hintText: "Enter child's last name",
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    validator: _validateChildLastName,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassDropdown<String>(
                    label: 'Child Ext',
                    isRequired: false,
                    value: child.extensionName,
                    items: _suffixOptions
                        .map(
                          (ext) => DropdownMenuItem<String>(
                            value: ext,
                            child: Text(ext.isEmpty ? 'None' : ext),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => child.extensionName = val ?? ''),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassDatePickerField(
                    controller: child.birthdayController,
                    label: 'Date of Birth',
                    isRequired: true,
                    hintText: 'YYYY-MM-DD',
                    onTap: () => _selectChildBirthday(index),
                    validator: (_) => _validateChildBirthday(child),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 7: CHARACTER REFERENCES (OPTIONAL)
  // ---------------------------------------------------------------------------
  Widget _buildCharacterReferencesSection() {
    return Container(
      key: _referencesSectionKey,
      child: _buildSectionCard(
        title: 'Character References (Optional)',
        icon: Icons.people_outline,
        children: [
          _buildGlassTextField(
            controller: _ref1Controller,
            label: 'Reference Member 1 Name',
            isRequired: false,
            hintText: 'Enter first reference full name',
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            validator: _validateReferenceName,
          ),
          const SizedBox(height: 14),
          _buildGlassTextField(
            controller: _ref2Controller,
            label: 'Reference Member 2 Name',
            isRequired: false,
            hintText: 'Enter second reference full name',
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            validator: _validateReferenceName,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 8: MEMBER SIGNATURE (OPTIONAL)
  // ---------------------------------------------------------------------------
  Widget _buildSignatureSection() {
    return _buildSectionCard(
      title: 'Member Signature (Optional)',
      icon: Icons.draw_outlined,
      children: [
        Center(
          child: Column(
            children: [
              CustomPaint(
                painter: _DashedBorderPainter(
                  color: _signatureError != null ? _errorRed : _cyanAccent,
                  strokeWidth: 2,
                  borderRadius: 12,
                ),
                child: Container(
                  width: 180,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _signatureBytes != null ? Colors.white : _inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _signatureBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _signatureBytes!,
                            width: 180,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Signature Preview (180x72)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickSignaturePhoto,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Upload Signature Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cyanAccent,
                      side: const BorderSide(color: _cyanAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _openSignaturePadDialog,
                    icon: const Icon(Icons.gesture, size: 18),
                    label: const Text('Draw Signature on Pad'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_signatureBytes != null)
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                                _signatureBytes = null;
                                _signatureDataUrl = null;
                                _signatureName = null;
                                _signatureError = null;
                              }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _errorRed,
                        side: const BorderSide(color: _errorRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
              if (_signatureName != null) ...[
                const SizedBox(height: 6),
                Text(
                  _signatureName!,
                  style: const TextStyle(color: _cyanAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                "Scanned image or photo of the member's handwritten signature. Accepted: JPG or PNG · Max 2 MB.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
              if (_signatureError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _signatureError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BUTTONS (CANCEL & REGISTER MEMBER)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/admin');
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _onRegisterTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyanAccent,
              foregroundColor: _bgDeepNavy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _bgDeepNavy,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1, size: 20),
            label: Text(
              _isSubmitting ? 'Registering...' : 'Register Member',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE GLASSMORPHIC WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _cyanAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: _errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _glassInputDecoration({
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _inputFill,
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _cyanAccent, size: 19)
          : null,
      suffixIcon: suffixIcon,
      counterText: '',
      errorMaxLines: 3,
      errorStyle: const TextStyle(
        color: _errorRed,
        fontSize: 12,
        height: 1.3,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _cyanAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _errorRed, width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _errorRed, width: 1.6),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    String? hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: _glassInputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown<T>({
    required String label,
    required bool isRequired,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: _bgDarkNavy,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: hintText != null
              ? Text(
                  hintText,
                  style: const TextStyle(color: Colors.white38, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          validator: validator,
          decoration: _glassInputDecoration(),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGlassDatePickerField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required String hintText,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: _glassInputDecoration(
            hintText: hintText,
            prefixIcon: Icons.calendar_today_outlined,
            suffixIcon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders a 2px dashed rounded rectangular border.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.borderRadius = 12.0,
    this.dashWidth = 6.0,
    this.dashGap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Interactive signature drawing dialog returning PNG bytes.
class _SignaturePadDialog extends StatefulWidget {
  const _SignaturePadDialog();

  @override
  State<_SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<_SignaturePadDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _exportPng() async {
    if (_strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    const width = 360.0;
    const height = 144.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    final strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.of(context).pop(byteData?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Draw Member Signature',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 300,
            height: 144,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00C2A8), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                    _strokes.add(_currentStroke!);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke?.add(details.localPosition);
                  });
                },
                onPanEnd: (_) => _currentStroke = null,
                child: CustomPaint(
                  painter: _SignatureStrokePainter(_strokes),
                  size: const Size(300, 144),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign inside the white box using your finger or stylus.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _clear,
          child: const Text(
            'Clear',
            style: TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _exportPng,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C2A8),
            foregroundColor: const Color(0xFF0B132B),
          ),
          child: const Text(
            'Use Signature',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _SignatureStrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  const _SignatureStrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureStrokePainter oldDelegate) => true;
}
