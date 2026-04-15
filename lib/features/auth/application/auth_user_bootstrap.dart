import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/campus_domains.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';

class AuthUserBootstrap {
  static String formatAuthError(Object error) {
    if (error is FirebaseAuthException) {
      final code = error.code;
      final message = error.message ?? 'No message provided';
      return '$code: $message';
    }

    return error.toString();
  }

  static String loginErrorRoute(String message) {
    return '/login?error=${Uri.encodeComponent(message)}';
  }

  static Future<void> signOutEverywhere(
    /*{GoogleSignIn? googleSignIn}*/
  ) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    /*try {
      await googleSignIn?.signOut();
    } catch (_) {}*/
  }

  static Future<void> ensureUserProfile(User user) async {
    final email = (user.email ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      throw Exception('Authentication failed: Google account email is missing');
    }

    final domain = email.contains('@') ? email.split('@').last.trim() : '';
    final campusIdFromEmail = campusDomains[domain];
    if (campusIdFromEmail == null) {
      throw Exception('Use your student email to continue');
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnap = await docRef
        .tracedGet('users/${user.uid} auth bootstrap')
        .timeout(const Duration(seconds: 8));

    if (!docSnap.exists) {
      await docRef
          .set({
            'uid': user.uid,
            'name': _resolveDisplayName(user),
            'email': email,
            'phone': null,
            'campus_id': campusIdFromEmail,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 8));

      await _cacheCampusId(campusIdFromEmail);
      return;
    }

    final data = docSnap.data();
    if (data == null) {
      throw Exception('User profile data is missing');
    }

    final existingCampusId = (data['campus_id'] as String?)?.trim();
    final effectiveCampusId = (existingCampusId?.isNotEmpty ?? false)
        ? existingCampusId
        : campusIdFromEmail;

    final updates = <String, dynamic>{};
    if ((data['email'] as String?) != email) {
      updates['email'] = email;
    }
    if ((data['name'] as String?)?.trim().isEmpty ?? true) {
      updates['name'] = _resolveDisplayName(user);
    }
    final normalizedPhone = PhoneGateUtils.normalizePhone(data['phone']);
    if (normalizedPhone != null &&
        data['phone']?.toString() != normalizedPhone) {
      updates['phone'] = normalizedPhone;
    }
    if ((existingCampusId?.isEmpty ?? true)) {
      updates['campus_id'] = campusIdFromEmail;
    }

    if (updates.isNotEmpty) {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await docRef
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    }

    if (effectiveCampusId == null || effectiveCampusId.isEmpty) {
      throw Exception('Unable to determine your campus');
    }

    await _cacheCampusId(effectiveCampusId);
  }

  static Future<void> _cacheCampusId(String campusId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campus_id', campusId);
  }

  static String _resolveDisplayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName == null || displayName.isEmpty) {
      return 'New User';
    }
    return displayName;
  }
}
