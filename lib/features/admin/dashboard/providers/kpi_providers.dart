import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kpi_providers.g.dart';

DateTime? _extractDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

@riverpod
Stream<int> totalMembersCount(Ref ref) {
  return FirebaseFirestore.instance
      .collection('member')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

@riverpod
Stream<int> activeSurveysCount(Ref ref) {
  return FirebaseFirestore.instance
      .collection('surveys')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();
          final status = data['status']?.toString().toLowerCase();
          final isActiveFlag = data['isActive'] == true;
          return status == 'active' || isActiveFlag;
        }).length;
      });
}

@riverpod
Stream<int> newAccountsTodayCount(Ref ref) {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  return FirebaseFirestore.instance
      .collection('member')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();
          final created = _extractDateTime(
            data['created_at'] ?? data['registeredAt'] ?? data['registered_at'],
          );
          return created != null && !created.isBefore(startOfDay);
        }).length;
      });
}

@riverpod
Stream<int> recentUpdatesCount(Ref ref) {
  return FirebaseFirestore.instance
      .collection('member')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();
          return data['updated_at'] != null;
        }).length;
      });
}

