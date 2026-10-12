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

  Future<void> deleteMember(String id) async {
    await _membersRef.doc(id).delete();
  }
}
