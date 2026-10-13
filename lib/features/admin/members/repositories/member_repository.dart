import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/member.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_repository.g.dart';

@riverpod
MemberRepository memberRepository(Ref ref) {
  return MemberRepository(FirebaseFirestore.instance);
}

class MemberRepository {
  final FirebaseFirestore _firestore;

  MemberRepository(this._firestore);

  CollectionReference<Member> get _membersRef => _firestore
      .collection('member')
      .withConverter<Member>(
        fromFirestore: (snapshot, _) {
          final data = snapshot.data() ?? {};
          data['account_number'] = data['account_number'] ?? '';
          data['firstname'] = data['firstname'] ?? '';
          data['lastname'] = data['lastname'] ?? '';
          
          if (!data.containsKey('passport_photo') ||
              data['passport_photo'] == null) {
            data['passport_photo'] =
                data['photoUrl'] ??
                data['photo_url'] ??
                data['photo'] ??
                data['profilePic'];
          }
          if (!data.containsKey('signature_photo') ||
              data['signature_photo'] == null) {
            data['signature_photo'] =
                data['signatureUrl'] ??
                data['signature_url'] ??
                data['signature'];
          }
          if (!data.containsKey('created_at') || data['created_at'] == null) {
            data['created_at'] = data['registeredAt'] ?? data['registered_at'];
          }
          return Member.fromJson({...data, 'id': snapshot.id});
        },
        toFirestore: (member, _) {
          final json = member.toJson();
          json.remove('id');
          return json;
        },
      );

  Stream<List<Member>> getMembers() {
    return _membersRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Future<Member?> getMemberOnce(String id, {String? accountNumber}) async {
    try {
      final docSnap = await _membersRef.doc(id).get();
      if (docSnap.exists && docSnap.data() != null) {
        return docSnap.data();
      }

      final byMemberId = await _membersRef
          .where('member_id', isEqualTo: id)
          .limit(1)
          .get();
      if (byMemberId.docs.isNotEmpty) {
        return byMemberId.docs.first.data();
      }

      if (accountNumber != null && accountNumber.isNotEmpty) {
        final byAcc = await _membersRef
            .where('account_number', isEqualTo: accountNumber)
            .limit(1)
            .get();
        if (byAcc.docs.isNotEmpty) {
          return byAcc.docs.first.data();
        }
      }
    } catch (_) {}
    return null;
  }

  Stream<Member?> getMember(String id, {String? accountNumber}) async* {
    try {
      final docSnap = await _membersRef.doc(id).get();
      if (docSnap.exists && docSnap.data() != null) {
        yield* _membersRef.doc(id).snapshots().map((s) => s.data());
        return;
      }

      final byMemberId = await _membersRef
          .where('member_id', isEqualTo: id)
          .limit(1)
          .get();
      if (byMemberId.docs.isNotEmpty) {
        final targetDocId = byMemberId.docs.first.id;
        yield* _membersRef.doc(targetDocId).snapshots().map((s) => s.data());
        return;
      }

      if (accountNumber != null && accountNumber.isNotEmpty) {
        final byAcc = await _membersRef
            .where('account_number', isEqualTo: accountNumber)
            .limit(1)
            .get();
        if (byAcc.docs.isNotEmpty) {
          final targetDocId = byAcc.docs.first.id;
          yield* _membersRef.doc(targetDocId).snapshots().map((s) => s.data());
          return;
        }
      }
    } catch (_) {}

    yield* _membersRef.doc(id).snapshots().map((s) => s.data());
  }

  Future<void> addMember(Member member) async {
    await _membersRef.add(member);
  }

  Future<void> updateMember(Member member) async {
    await _membersRef.doc(member.id).set(member, SetOptions(merge: true));
  }

  Future<void> updateMemberInfo({
    required String memberId,
    required Map<String, dynamic> personalData,
    Map<String, dynamic>? parentsData,
    Map<String, dynamic>? spouseData,
    List<Map<String, dynamic>>? childrenData,
    List<String>? referencesData,
  }) async {
    final memberUpdate = Map<String, dynamic>.from(personalData);
    if (parentsData != null) {
      memberUpdate['father_name'] = parentsData['father_name'];
      memberUpdate['mother_name'] = parentsData['mother_name'];
    }
    if (spouseData != null) {
      memberUpdate['spouse_name'] = spouseData['spouse_name'];
      memberUpdate['spouse_occupation'] = spouseData['occupation'];
      memberUpdate['spouse_employer'] = spouseData['employer'];
    } else {
      memberUpdate['spouse_name'] = null;
      memberUpdate['spouse_occupation'] = null;
      memberUpdate['spouse_employer'] = null;
    }
    if (childrenData != null) {
      memberUpdate['children'] = childrenData;
    }
    if (referencesData != null) {
      memberUpdate['references'] = referencesData;
    }
    memberUpdate['updated_at'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('member')
        .doc(memberId)
        .set(memberUpdate, SetOptions(merge: true));

    // Sync parents collection
    if (parentsData != null) {
      final pQ = await _firestore
          .collection('parents')
          .where('member_id', isEqualTo: memberId)
          .get();
      if (pQ.docs.isNotEmpty) {
        await pQ.docs.first.reference.update({
          'father_name': parentsData['father_name'] ?? '',
          'mother_name': parentsData['mother_name'] ?? '',
        });
      } else {
        await _firestore.collection('parents').add({
          'member_id': memberId,
          'father_name': parentsData['father_name'] ?? '',
          'mother_name': parentsData['mother_name'] ?? '',
        });
      }
    }

    // Sync spouse collection
    final sQ = await _firestore
        .collection('spouse')
        .where('member_id', isEqualTo: memberId)
        .get();
    if (personalData['civil_status'] == 'Married' && spouseData != null) {
      if (sQ.docs.isNotEmpty) {
        await sQ.docs.first.reference.update({
          'spouse_name': spouseData['spouse_name'] ?? '',
          'occupation': spouseData['occupation'] ?? '',
          'employer': spouseData['employer'] ?? '',
        });
      } else {
        await _firestore.collection('spouse').add({
          'member_id': memberId,
          'spouse_name': spouseData['spouse_name'] ?? '',
          'occupation': spouseData['occupation'] ?? '',
          'employer': spouseData['employer'] ?? '',
        });
      }
    } else {
      for (final d in sQ.docs) {
        await d.reference.delete();
      }
    }

    // Sync children collection
    if (childrenData != null) {
      final cQ = await _firestore
          .collection('children')
          .where('member_id', isEqualTo: memberId)
          .get();
      for (final d in cQ.docs) {
        await d.reference.delete();
      }
      for (final c in childrenData) {
        final name = (c['child_name'] ?? '').toString().trim();
        final bday = (c['birthday'] ?? '').toString().trim();
        if (name.isNotEmpty || bday.isNotEmpty) {
          await _firestore.collection('children').add({
            'member_id': memberId,
            'child_name': name,
            'birthday': bday,
          });
        }
      }
    }

    // Sync member_references collection
    if (referencesData != null) {
      final rQ = await _firestore
          .collection('member_references')
          .where('member_id', isEqualTo: memberId)
          .get();
      for (final d in rQ.docs) {
        await d.reference.delete();
      }
      for (final r in referencesData) {
        final rTrim = r.trim();
        if (rTrim.isNotEmpty) {
          await _firestore.collection('member_references').add({
            'member_id': memberId,
            'reference_member_name': rTrim,
          });
        }
      }
    }

    // Record update history
    try {
      await _firestore
          .collection('member')
          .doc(memberId)
          .collection('update_history')
          .add({
        'member_id': memberId,
        'updated_by_member_id': memberId,
        'update_type': 'Information Update',
        'remarks': 'Member updated their own profile information via mobile app.',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> updateMemberPhoto({
    required String memberId,
    required String currentUid,
    required String photoFilename,
  }) async {
    await _firestore.collection('member').doc(memberId).set({
      'passport_photo': photoFilename,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await _firestore
          .collection('member')
          .doc(memberId)
          .collection('update_history')
          .add({
        'member_id': currentUid,
        'updated_by_member_id': currentUid,
        'update_type': 'photo_upload',
        'remarks': 'Member uploaded a new passport photo.',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getChildren(String memberId) async {
    try {
      final snap = await _firestore
          .collection('children')
          .where('member_id', isEqualTo: memberId)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteMember(String id) async {
    await _membersRef.doc(id).delete();
  }
}

