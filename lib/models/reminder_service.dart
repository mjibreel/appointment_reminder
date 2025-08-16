import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> addReminder({
    required String medicationName,
    required String dosage,
    required List<String> times,
    required int days,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('reminders').add({
        'userId': user.uid,
        'medicationName': medicationName,
        'dosage': dosage,
        'times': times,
        'days': days,
        'createdAt': FieldValue.serverTimestamp(),
        'isDone': false,
      });
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get reminders: $e');
    }
  }

  static Future<void> updateReminder(String reminderId, bool isDone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('reminders').doc(reminderId).update({
        'isDone': isDone,
      });
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  static Future<void> deleteReminder(String reminderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('reminders').doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }
}

