import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/member.dart';
import '../providers/member_provider.dart';

class MemberDetailsScreen extends ConsumerWidget {
  final String memberId;

  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13172E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13172E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.assignment_ind, color: Colors.pinkAccent),
            const SizedBox(width: 8),
            const Text(
              'Member Profile Record',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: membersAsync.when(
        data: (members) {
          final member = members.firstWhere((m) => m.id == memberId,
              orElse: () => throw Exception('Member not found'));
          return _buildBody(context, member);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Member member) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.teal, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      member.status,
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrimaryInfoCard(member),
          const SizedBox(height: 16),
          _buildContactInfoCard(member),
          const SizedBox(height: 16),
          _buildEmploymentInfoCard(member),
          const SizedBox(height: 16),
          _buildFamilyInfoCard(member),
          const SizedBox(height: 16),
          _buildSignatureCard(member),
          const SizedBox(height: 24),
          _buildActionButtons(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPrimaryInfoCard(Member member) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A3B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                ),
                child: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: member.photoUrl!.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(member.photoUrl!.split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              )
                            : Image.network(
                                member.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'OFFICIAL 2X2 PHOTO',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${member.firstName} ${member.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text(
                          'ACCOUNT NO: ',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            member.accountNumber,
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.teal, height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CIVIL STATUS'),
                            _buildValue(member.civilStatus ?? 'N/A'),
                            const SizedBox(height: 12),
                            _buildLabel('DATE OF BIRTH & AGE'),
                            _buildValue(member.dateOfBirth ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('SEX / GENDER'),
                            _buildValue(member.gender ?? 'N/A'),
                            const SizedBox(height: 12),
                            _buildLabel('NATIONALITY'),
                            _buildValue(member.nationality ?? 'N/A'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(Member member) {
    return _buildSectionCard(
      title: 'Contact & Residence Information',
      icon: Icons.contact_mail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('CONTACT NUMBER'),
                    _buildValue(member.phone ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('EMAIL ADDRESS'),
                    _buildValue(member.email ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabel('HOME ADDRESS'),
          _buildValue(member.homeAddress ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildEmploymentInfoCard(Member member) {
    return _buildSectionCard(
      title: 'Employment & Business Information',
      icon: Icons.work,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('OCCUPATION / PROFESSION'),
                    _buildValue(member.occupation ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('EMPLOYER / BUSINESS NAME'),
                    _buildValue(member.employerName ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabel('EMPLOYER BUSINESS ADDRESS'),
          _buildValue(member.employerAddress ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoCard(Member member) {
    return _buildSectionCard(
      title: 'Family Information',
      icon: Icons.family_restroom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E213A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people, color: Colors.pinkAccent, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text('PARENTS INFORMATION',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      const TextSpan(text: 'FATHER: ', style: TextStyle(color: Colors.grey)),
                      TextSpan(text: member.fatherName ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      const TextSpan(text: 'MOTHER: ', style: TextStyle(color: Colors.grey)),
                      TextSpan(text: member.motherName ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E213A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text('SPOUSE INFORMATION',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.pinkAccent, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(member.spouseName ?? 'N/A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('OCCUPATION:', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(member.spouseOccupation ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EMPLOYER:', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(member.spouseEmployer ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(Member member) {
    return _buildSectionCard(
      title: 'Handwritten E-Signature',
      icon: Icons.draw,
      child: Center(
        child: Column(
          children: [
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: (member.signatureUrl != null && member.signatureUrl!.isNotEmpty)
                  ? (member.signatureUrl!.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(member.signatureUrl!.split(',').last),
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('Invalid Signature', style: TextStyle(color: Colors.red)),
                          ),
                        )
                      : Image.network(
                          member.signatureUrl!,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('Invalid Signature', style: TextStyle(color: Colors.red)),
                          ),
                        ))
                  : const Center(child: Text('No Signature', style: TextStyle(color: Colors.black))),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Flexible(
                  child: Text('Official Handwritten Signature on File',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print),
              label: const Text('Print Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
          label: const Text('Close View'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E213A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
