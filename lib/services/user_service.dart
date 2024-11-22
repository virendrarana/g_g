import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (error) {
      throw error;
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (error) {
      throw error;
    }
  }

  // Get user's order history
  Future<List<DocumentSnapshot>> getUserOrderHistory(String uid) async {
    try {
      QuerySnapshot orderHistory = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('orderDate', descending: true)
          .get();
      return orderHistory.docs;
    } catch (error) {
      throw error;
    }
  }
}
