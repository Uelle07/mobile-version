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
            fromFirestore: (snapshot, _) =>
                Member.fromJson({...snapshot.data()!, 'id': snapshot.id}),
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
