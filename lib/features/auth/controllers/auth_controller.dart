import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

part 'auth_controller.g.dart';

class AuthStateData {
  final User? user;
  final UserRole role;

  AuthStateData({this.user, this.role = UserRole.unknown});
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<AuthStateData> build() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return AuthStateData(user: null, role: UserRole.unknown);
      }
      final role = await _checkUserRole(user);
      return AuthStateData(user: user, role: role);
    });
  }

  Future<UserRole> _checkUserRole(User user) async {
    try {
      final staffDoc = await _firestore.collection('staff').doc(user.uid).get();
      if (staffDoc.exists) {
        return UserRole.admin;
      }
      return UserRole.member;
    } catch (e) {
      return UserRole.unknown;
    }
  }

  Future<String?> signIn(String identifier, String password) async {
    try {
      final email = identifier.contains('@')
          ? identifier
          : '$identifier@space.coop';
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return 'Too many failed attempts. Account is temporarily locked.';
      }
      return 'Invalid Account Number/Username or password.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(
    String identifier,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final email = identifier.contains('@')
          ? identifier
          : '$identifier@space.coop';
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Also add to member collection
      await _firestore.collection('member').doc(userCredential.user!.uid).set({
        'account_number': identifier,
        'firstname': firstName,
        'lastname': lastName,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
