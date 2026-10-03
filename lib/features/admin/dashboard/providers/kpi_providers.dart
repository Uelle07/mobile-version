import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kpi_providers.g.dart';

@riverpod
Stream<int> totalMembersCount(Ref ref) {
  return FirebaseFirestore.instance.collection('member').snapshots().map((snapshot) => snapshot.docs.length);
}

@riverpod
Stream<int> activeSurveysCount(Ref ref) {
  return FirebaseFirestore.instance
      .collection('surveys')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

@riverpod
Stream<int> newAccountsTodayCount(Ref ref) {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  
  return FirebaseFirestore.instance
      .collection('member')
      .where('registeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}
