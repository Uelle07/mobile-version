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

  CollectionReference<Member> get _membersRef =>
      _firestore.collection('member').withConverter<Member>(
            fromFirestore: (snapshot, _) {
              final data = snapshot.data() ?? {};
              if (!data.containsKey('passport_photo') || data['passport_photo'] == null) {
                data['passport_photo'] = data['photoUrl'] ?? data['photo_url'] ?? data['photo'] ?? data['profilePic'];
              }
              if (!data.containsKey('signature_photo') || data['signature_photo'] == null) {
                data['signature_photo'] = data['signatureUrl'] ?? data['signature_url'] ?? data['signature'];
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
