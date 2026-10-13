import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/member.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../admin/members/providers/member_provider.dart';
import '../../../admin/members/repositories/member_repository.dart';
import '../../dashboard/providers/current_member_provider.dart';

class PhotoUploadScreen extends ConsumerStatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageSize;
  String? _selectedImageName;

  bool _isUploading = false;
  String? _errorMessage;

  // Maximum allowed file size: 2 MB (2 * 1024 * 1024 bytes)
  static const int _maxFileSizeBytes = 2 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentMemberProvider);

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Navigation Button
                    _buildBackNavigationButton(),
                    const SizedBox(height: 16),

                    // Error Alert Banner (if any)
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(_errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // Main Glassmorphism Card
                    _buildUploadCard(memberAsync),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Back navigation button matching web portal's "← Dashboard"
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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

  /// Red dismissible alert banner displaying error messages
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
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
                  'Upload Failed:',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  /// Main Glassmorphic Card Container
  Widget _buildUploadCard(AsyncValue<Member?> memberAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          // Header Section
          _buildCardHeader(),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 24),

          // Section A: Current Photo Live Preview
          _buildPhotoPreviewSection(memberAsync),

          const SizedBox(height: 24),

          // Section B: Image Selection Controls
          _buildSelectionControls(),

          const SizedBox(height: 16),

          // Format & Size Guidance Text
          _buildGuidanceBox(),

          const SizedBox(height: 28),

          // Section C: Action Buttons (Upload & Cancel)
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Card Header: Camera Badge Icon, Title & Subtitle
  Widget _buildCardHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Camera Badge Icon with Cyan Glow
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Color(0xFF00F2FE),
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Upload Profile Photo',
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
                'Upload or replace your official 2x2 / passport-size member photo.',
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

  /// Section A: Current Photo Live Preview
  Widget _buildPhotoPreviewSection(AsyncValue<Member?> memberAsync) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 140x140 Avatar Frame with Cyan Border and Glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF13172E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00F2FE),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.5),
                  child: _buildPreviewImage(memberAsync),
                ),
              ),

              // Overlay Badge at bottom-right corner
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF0B132B),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Caption Label
        Text(
          _selectedImageBytes != null
              ? 'New Photo Preview (Ready to Upload)'
              : 'Active Passport Photo on Record',
          style: TextStyle(
            color: _selectedImageBytes != null
                ? const Color(0xFF00F2FE)
                : Colors.white60,
            fontSize: 12.5,
            fontWeight: _selectedImageBytes != null
                ? FontWeight.w600
                : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ],
    );
  }

  /// Builds the image widget for the preview container
  Widget _buildPreviewImage(AsyncValue<Member?> memberAsync) {
    // 1. If user just selected a new file, immediately show the picked image
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: 140,
        height: 140,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarPlaceholder(),
      );
    }

    // 2. Otherwise display active photo on record from Firestore
    return memberAsync.maybeWhen(
      data: (member) {
        final photo = member?.photoUrl;
        if (photo == null || photo.isEmpty) {
          return _buildDefaultAvatarPlaceholder();
        }

        // Full web URL
        if (photo.startsWith('http://') || photo.startsWith('https://')) {
          return Image.network(
            photo,
            fit: BoxFit.cover,
            width: 140,
            height: 140,
            errorBuilder: (_, __, ___) => _buildDefaultAvatarPlaceholder(),
          );
        }

        // Filename from PHP backend
        final lower = photo.toLowerCase();
        if (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif')) {
          String baseUrl =
              'http://localhost/cooperative-member-information-system/uploads/';
          try {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              baseUrl =
                  'http://10.0.2.2/cooperative-member-information-system/uploads/';
            }
          } catch (_) {}

          return Image.network(
            '$baseUrl$photo',
            fit: BoxFit.cover,
            width: 140,
            height: 140,
            errorBuilder: (_, __, ___) => _buildDefaultAvatarPlaceholder(),
          );
        }

        // Base64 Data URL fallback
        try {
          final base64String = photo.contains(',')
              ? photo.split(',').last.replaceAll(RegExp(r'\s+'), '')
              : photo.replaceAll(RegExp(r'\s+'), '');
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            width: 140,
            height: 140,
            errorBuilder: (_, __, ___) => _buildDefaultAvatarPlaceholder(),
          );
        } catch (_) {
          return _buildDefaultAvatarPlaceholder();
        }
      },
      orElse: () => _buildDefaultAvatarPlaceholder(),
    );
  }

  Widget _buildDefaultAvatarPlaceholder() {
    return Container(
      color: const Color(0xFF13172E),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 70,
        color: Colors.white54,
      ),
    );
  }

  /// Section B: Image Selection Controls
  Widget _buildSelectionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Option 1: Camera capture
            Expanded(
              child: _buildPickerOptionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Take New Photo',
                subtitle: 'Use Camera',
                onTap: _isUploading
                    ? null
                    : () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            // Option 2: Gallery picker
            Expanded(
              child: _buildPickerOptionCard(
                icon: Icons.photo_library_outlined,
                title: 'Select from Gallery',
                subtitle: 'Browse Files',
                onTap: _isUploading
                    ? null
                    : () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),

        // If file is selected, display file summary chip
        if (_selectedImageName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00F2FE),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedImageName (${_selectedImageSize ?? ""})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                InkWell(
                  onTap: _isUploading ? null : _clearSelectedImage,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.white60, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPickerOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF00F2FE), size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Guidance Text Box
  Widget _buildGuidanceBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF00F2FE),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Accepted formats: JPG, JPEG, PNG. Maximum file size: 2 MB.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Section C: Action Buttons (Upload & Cancel) with Zero-Overflow Row Protection
  Widget _buildActionButtons() {
    return Row(
      children: [
        // "Upload Photo" Button: Primary Gradient Cyan/Teal
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: _isUploading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isUploading ? Colors.grey[800] : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isUploading
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 20),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Photo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.3,
                ),
                softWrap: true,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // "Cancel" Button: Outlined
        Expanded(
          child: OutlinedButton(
            onPressed: _isUploading
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
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
      ],
    );
  }

  /// Pick Image Handler with Validation
  Future<void> _pickImage(ImageSource source) async {
    setState(() => _errorMessage = null);

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // 1. Format / MIME Validation
      final name = pickedFile.name.toLowerCase();
      final ext = name.contains('.') ? name.split('.').last : '';
      const allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExts.contains(ext)) {
        setState(() {
          _errorMessage = 'Only JPG and PNG images are allowed.';
        });
        return;
      }

      // 2. File Size Limit Validation (2 MB)
      final bytes = await pickedFile.readAsBytes();
      if (bytes.lengthInBytes > _maxFileSizeBytes) {
        setState(() {
          _errorMessage =
              'The selected image exceeds the 2MB limit. Please choose a smaller image.';
        });
        return;
      }

      final sizeMb =
          (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2);

      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
        _selectedImageSize = '$sizeMb MB';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select photo: $e';
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImageSize = null;
    });
  }

  /// Upload Execution & Firestore Update
  Future<void> _handleUpload() async {
    if (_isUploading) return;
    setState(() => _errorMessage = null);

    // 1. File Selection Check
    if (_selectedImage == null || _selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select a photo file to proceed with your upload.';
      });
      return;
    }

    // 2. Re-verify File Size Limit (2 MB)
    if (_selectedImageBytes!.lengthInBytes > _maxFileSizeBytes) {
      setState(() {
        _errorMessage =
            'The selected image exceeds the 2MB limit. Please choose a smaller image.';
      });
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User session expired. Please log in again.';
          _isUploading = false;
        });
        return;
      }

      final uid = currentUser.uid;
      final ext = _selectedImage!.name.contains('.')
          ? _selectedImage!.name.toLowerCase().split('.').last
          : 'jpg';
      final mime = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final photoDataUrl =
          'data:$mime;base64,${base64Encode(_selectedImageBytes!)}';

      // 3. Update Firestore Member Document & Record Audit Log
      final memberRepo = ref.read(memberRepositoryProvider);

      // Determine active member document ID
      String memberDocId = uid;
      final currentMember = ref.read(currentMemberProvider).value;
      if (currentMember != null && currentMember.id.isNotEmpty) {
        memberDocId = currentMember.id;
      } else {
        final directDoc = await FirebaseFirestore.instance
            .collection('member')
            .doc(uid)
            .get();
        if (!directDoc.exists) {
          final querySnap = await FirebaseFirestore.instance
              .collection('member')
              .where('member_id', isEqualTo: uid)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            memberDocId = querySnap.docs.first.id;
          }
        }
      }

      await memberRepo.updateMemberPhoto(
        memberId: memberDocId,
        currentUid: uid,
        photoFilename: photoDataUrl,
      );

      // Invalidate providers so home tab, profile tab, and admin list reload fresh photo
      ref.invalidate(currentMemberProvider);
      ref.invalidate(membersProvider);

      if (!mounted) return;

      // 4. Success State: SnackBar & Return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Photo updated successfully.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        GoRouter.of(context).go('/member');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during upload: $e';
          _isUploading = false;
        });
      }
    }
  }
}
