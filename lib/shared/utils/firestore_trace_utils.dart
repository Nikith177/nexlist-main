import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _currentUserId() => FirebaseAuth.instance.currentUser?.uid ?? 'null';

void _logAttempt(String target) {
  print('FIRESTORE: attempting read, user = ${_currentUserId()}');
  print('FIRESTORE: target = $target');
}

void _logError(String target, Object error) {
  print('FIRESTORE ERROR: $error');
  print('FIRESTORE: failed target = $target');
}

extension FirestoreQueryTraceExtension<T extends Object?> on Query<T> {
  Future<QuerySnapshot<T>> tracedGet(String target) async {
    _logAttempt(target);
    try {
      return await get();
    } catch (error) {
      _logError(target, error);
      rethrow;
    }
  }

  Stream<QuerySnapshot<T>> tracedSnapshots(String target) {
    _logAttempt(target);
    try {
      return snapshots().handleError((Object error, StackTrace stackTrace) {
        _logError(target, error);
      });
    } catch (error) {
      _logError(target, error);
      rethrow;
    }
  }
}

extension FirestoreDocumentTraceExtension<T extends Object?>
    on DocumentReference<T> {
  Future<DocumentSnapshot<T>> tracedGet(String target) async {
    _logAttempt(target);
    try {
      return await get();
    } catch (error) {
      _logError(target, error);
      rethrow;
    }
  }

  Stream<DocumentSnapshot<T>> tracedSnapshots(String target) {
    _logAttempt(target);
    try {
      return snapshots().handleError((Object error, StackTrace stackTrace) {
        _logError(target, error);
      });
    } catch (error) {
      _logError(target, error);
      rethrow;
    }
  }
}
