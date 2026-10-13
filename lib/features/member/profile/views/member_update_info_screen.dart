import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/member.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../admin/members/repositories/member_repository.dart';
import '../../dashboard/providers/current_member_provider.dart';

class _ChildEntry {
  final TextEditingController nameController;
  DateTime? birthday;

  _ChildEntry({String name = '', this.birthday})
      : nameController = TextEditingController(text: name);

  void dispose() {
    nameController.dispose();
  }
}

class MemberUpdateInfoScreen extends ConsumerStatefulWidget {
  const MemberUpdateInfoScreen({super.key});

  @override
  ConsumerState<MemberUpdateInfoScreen> createState() =>
      _MemberUpdateInfoScreenState();
}

class _MemberUpdateInfoScreenState
    extends ConsumerState<MemberUpdateInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _initialized = false;
  bool _isSaving = false;

  // Personal Info Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _extensionName = '';
  String _sex = 'Male';
  String _civilStatus = 'Single';
  final _nationalityController = TextEditingController(text: 'Filipino');
  DateTime? _birthday;
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  // Employment
  final _occupationController = TextEditingController();
  final _employerController = TextEditingController();
  final _employerAddressController = TextEditingController();

  // Parents
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();

  // Spouse
  final _spouseNameController = TextEditingController();
  final _spouseOccController = TextEditingController();
  final _spouseEmpController = TextEditingController();

  // Children
  final List<_ChildEntry> _children = [];

  // References
  final _ref1Controller = TextEditingController();
  final _ref2Controller = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _nationalityController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _employerController.dispose();
    _employerAddressController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _spouseNameController.dispose();
    _spouseOccController.dispose();
    _spouseEmpController.dispose();
    _ref1Controller.dispose();
    _ref2Controller.dispose();
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateFromMember(Member member) {
    if (_initialized) return;
    _initialized = true;

    _firstNameController.text = member.firstName;
    _middleNameController.text = member.middleName ?? '';
    _lastNameController.text = member.lastName;

    final gender = member.gender;
    if (gender != null && (gender == 'Male' || gender == 'Female')) {
      _sex = gender;
    }

    final cs = member.civilStatus;
    if (cs != null && cs.isNotEmpty) {
      _civilStatus = cs;
    }

    if (member.nationality != null && member.nationality!.isNotEmpty) {
      _nationalityController.text = member.nationality!;
    }

    if (member.dateOfBirth != null && member.dateOfBirth!.isNotEmpty) {
      try {
        _birthday = DateTime.parse(member.dateOfBirth!);
      } catch (_) {}
    }

    _contactController.text = member.phone ?? '';
    _addressController.text = member.homeAddress ?? '';

    _occupationController.text = member.occupation ?? '';
    _employerController.text = member.employerName ?? '';
    _employerAddressController.text = member.employerAddress ?? '';

    _fatherNameController.text = member.fatherName ?? '';
    _motherNameController.text = member.motherName ?? '';

    _spouseNameController.text = member.spouseName ?? '';
    _spouseOccController.text = member.spouseOccupation ?? '';
    _spouseEmpController.text = member.spouseEmployer ?? '';

    // Extract references
    final refs = (member.references ?? []).map((e) {
      if (e is Map) {
        return (e['name'] ?? e['reference_member_name'] ?? '').toString();
      }
      return e.toString();
    }).where((e) => e.isNotEmpty).toList();

    if (refs.isNotEmpty) _ref1Controller.text = refs[0];
    if (refs.length > 1) _ref2Controller.text = refs[1];

    // Load children from repository
    _loadChildren(member.id);
  }

  Future<void> _loadChildren(String memberId) async {
    try {
      final repo = ref.read(memberRepositoryProvider);
      final rawChildren = await repo.getChildren(memberId);
      if (mounted && rawChildren.isNotEmpty) {
        setState(() {
          for (final c in _children) {
            c.dispose();
          }
          _children.clear();
          for (final item in rawChildren) {
            DateTime? bday;
            final bdayStr = (item['birthday'] ?? '').toString();
            if (bdayStr.isNotEmpty) {
              try {
                bday = DateTime.parse(bdayStr);
              } catch (_) {}
            }
            _children.add(
              _ChildEntry(
                name: (item['child_name'] ?? '').toString(),
                birthday: bday,
              ),
            );
          }
        });
      }
    } catch (_) {}
  }

  void _addChild() {
    setState(() {
      _children.add(_ChildEntry());
    });
  }

  void _removeChild(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _birthday ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  Future<void> _selectChildBirthday(BuildContext context, int index) async {
    final now = DateTime.now();
    final initialDate = _children[index].birthday ?? DateTime(now.year - 10, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _children[index].birthday = picked;
      });
    }
  }

  Future<void> _promptConfirmSave(Member member) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your Date of Birth.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF13172E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: Theme.of(ctx).primaryColor, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Save Profile Updates?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to commit these changes to your cooperative membership information?',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(ctx).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(ctx).primaryColor, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'All modified personal and family details will be saved immediately to your official record.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _saveProfile(member);
    }
  }

  Future<void> _saveProfile(Member member) async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(memberRepositoryProvider);

      final personalData = <String, dynamic>{
        'firstname': _firstNameController.text.trim(),
        'middlename': _middleNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'extension_name': _extensionName,
        'sex': _sex,
        'civil_status': _civilStatus,
        'nationality': _nationalityController.text.trim(),
        'birthday': _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : '',
        'contact_number': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'employer': _employerController.text.trim(),
        'employer_address': _employerAddressController.text.trim(),
      };

      final parentsData = <String, dynamic>{
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
      };

      Map<String, dynamic>? spouseData;
      if (_civilStatus == 'Married') {
        spouseData = {
          'spouse_name': _spouseNameController.text.trim(),
          'occupation': _spouseOccController.text.trim(),
          'employer': _spouseEmpController.text.trim(),
        };
      }

      final childrenData = _children
          .map((c) => {
                'child_name': c.nameController.text.trim(),
                'birthday': c.birthday != null
                    ? DateFormat('yyyy-MM-dd').format(c.birthday!)
                    : '',
              })
          .where((c) =>
              (c['child_name'] as String).isNotEmpty ||
              (c['birthday'] as String).isNotEmpty)
          .toList();

      final referencesData = [
        _ref1Controller.text.trim(),
        _ref2Controller.text.trim(),
      ].where((r) => r.isNotEmpty).toList();

      await repo.updateMemberInfo(
        memberId: member.id,
        personalData: personalData,
        parentsData: parentsData,
        spouseData: spouseData,
        childrenData: childrenData,
        referencesData: referencesData,
      );

      // Invalidate stream provider to reload updated data immediately
      ref.invalidate(currentMemberProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Your information has been updated successfully.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update information: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentMemberProvider);
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SpaceAppBar(
        title: Text('Update Information'),
      ),
      body: memberAsync.when(
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member record not found.'));
          }
          _populateFromMember(member);
          return _buildForm(context, member, primaryColor, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext context, Member member, Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Card
            _buildHeroCard(context, member, primaryColor, isDark),
            const SizedBox(height: 20),

            // Section 1: Personal Information
            _buildSectionCard(
              context: context,
              title: 'Personal Information',
              icon: Icons.badge_outlined,
              primaryColor: primaryColor,
              isDark: isDark,
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  isRequired: true,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _middleNameController,
                  label: 'Middle Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  isRequired: true,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Extension Name',
                  value: _extensionName,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('None')),
                    DropdownMenuItem(value: 'Jr.', child: Text('Jr.')),
                    DropdownMenuItem(value: 'Sr.', child: Text('Sr.')),
                    DropdownMenuItem(value: 'II', child: Text('II')),
                    DropdownMenuItem(value: 'III', child: Text('III')),
                    DropdownMenuItem(value: 'IV', child: Text('IV')),
                    DropdownMenuItem(value: 'V', child: Text('V')),
                  ],
                  onChanged: (val) =>
                      setState(() => _extensionName = val ?? ''),
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Sex',
                        value: _sex,
                        isRequired: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (val) =>
                            setState(() => _sex = val ?? 'Male'),
                        prefixIcon: Icons.wc_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Civil Status',
                        value: _civilStatus,
                        isRequired: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'Single', child: Text('Single')),
                          DropdownMenuItem(
                              value: 'Married', child: Text('Married')),
                          DropdownMenuItem(
                              value: 'Widowed', child: Text('Widowed')),
                          DropdownMenuItem(
                              value: 'Separated', child: Text('Separated')),
                          DropdownMenuItem(
                              value: 'Divorced', child: Text('Divorced')),
                        ],
                        onChanged: (val) =>
                            setState(() => _civilStatus = val ?? 'Single'),
                        prefixIcon: Icons.favorite_border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _nationalityController,
                  label: 'Nationality',
                  isRequired: true,
                  prefixIcon: Icons.flag_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Birthday Picker
                _buildBirthdayField(context, primaryColor, isDark),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _contactController,
                  label: 'Contact Number',
                  isRequired: true,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hintText: '0917-123-4567',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _addressController,
                  label: 'Full Home Address',
                  isRequired: true,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 2: Employment & Business
            _buildSectionCard(
              context: context,
              title: 'Employment & Business',
              icon: Icons.work_outline,
              primaryColor: primaryColor,
              isDark: isDark,
              children: [
                _buildTextField(
                  controller: _occupationController,
                  label: 'Occupation / Profession',
                  prefixIcon: Icons.business_center_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _employerController,
                  label: 'Employer / Business Name',
                  prefixIcon: Icons.apartment_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _employerAddressController,
                  label: 'Employer Address',
                  prefixIcon: Icons.map_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Parents Information
            _buildSectionCard(
              context: context,
              title: 'Section V. Parents Information',
              icon: Icons.family_restroom_outlined,
              primaryColor: primaryColor,
              isDark: isDark,
              children: [
                _buildTextField(
                  controller: _fatherNameController,
                  label: 'Father\'s Full Name',
                  prefixIcon: Icons.man_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _motherNameController,
                  label: 'Mother\'s Full/Maiden Name',
                  prefixIcon: Icons.woman_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 4: Spouse Information (only if Married)
            if (_civilStatus == 'Married') ...[
              _buildSectionCard(
                context: context,
                title: 'Spouse Information',
                icon: Icons.favorite,
                primaryColor: primaryColor,
                isDark: isDark,
                children: [
                  _buildTextField(
                    controller: _spouseNameController,
                    label: 'Spouse Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _spouseOccController,
                    label: 'Spouse Occupation',
                    prefixIcon: Icons.work_outline,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _spouseEmpController,
                    label: 'Spouse Employer',
                    prefixIcon: Icons.business_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Section 5: Children Information
            _buildSectionCard(
              context: context,
              title: 'Children Information',
              icon: Icons.child_care_outlined,
              primaryColor: primaryColor,
              isDark: isDark,
              children: [
                if (_children.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: isDark ? Colors.white60 : Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No children added yet. Tap "Add Child" below if applicable.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...List.generate(_children.length, (idx) {
                  final child = _children[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B213A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Child #${idx + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 13,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 20),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _removeChild(idx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: child.nameController,
                          label: 'Child Full Name',
                          prefixIcon: Icons.child_care,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectChildBirthday(context, idx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 18, color: primaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    child.birthday != null
                                        ? DateFormat.yMMMMd()
                                            .format(child.birthday!)
                                        : 'Select Child Birthday',
                                    style: TextStyle(
                                      color: child.birthday != null
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _addChild,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Child'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 6: Character References
            _buildSectionCard(
              context: context,
              title: 'Section VI. Character References',
              icon: Icons.people_outline,
              primaryColor: primaryColor,
              isDark: isDark,
              children: [
                _buildTextField(
                  controller: _ref1Controller,
                  label: 'Reference Member 1 Full Name',
                  prefixIcon: Icons.person_pin_outlined,
                  hintText: 'Full name of active cooperative member',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _ref2Controller,
                  label: 'Reference Member 2 Full Name',
                  prefixIcon: Icons.person_pin_outlined,
                  hintText: 'Full name of active cooperative member',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isSaving ? null : () => _promptConfirmSave(member),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      BuildContext context, Member member, Color primaryColor, bool isDark) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final borderColor = primaryColor.withValues(alpha: isDark ? 0.4 : 0.3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.edit_note_rounded, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update My Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep your cooperative membership information current and accurate.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'ACCT NO. ${member.accountNumber}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool isRequired = false,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    IconData? prefixIcon,
    bool isRequired = false,
  }) {
    // Check if value exists in items, otherwise fallback to first
    final hasValue = items.any((it) => it.value == value);
    final selectedValue = hasValue ? value : (items.first.value ?? '');

    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildBirthdayField(
      BuildContext context, Color primaryColor, bool isDark) {
    String dobText = 'Select Date of Birth *';
    int? age;
    if (_birthday != null) {
      dobText = DateFormat.yMMMMd().format(_birthday!);
      age = DateTime.now().year - _birthday!.year;
      if (DateTime.now().month < _birthday!.month ||
          (DateTime.now().month == _birthday!.month &&
              DateTime.now().day < _birthday!.day)) {
        age--;
      }
    }

    return InkWell(
      onTap: () => _selectBirthday(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth *',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    age != null ? '$dobText ($age Years Old)' : dobText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _birthday != null ? FontWeight.w600 : FontWeight.normal,
                      color: _birthday != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_month, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
