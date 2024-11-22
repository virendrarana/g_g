import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user object based on FirebaseUser
  UserModel _userFromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      fullName: '',
      email: user.email!,
      phoneNumber: '',
      role: 'customer',
      address: '',
    );
  }

  // Auth change user stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((User? user) {
      return user != null ? _userFromFirebaseUser(user) : null;
    });
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user!);
    } catch (error) {
      throw error;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(String email, String password, String fullName, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // Create a new document for the user with the uid
      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': 'customer',
        'address': '',
      });

      return _userFromFirebaseUser(user);
    } catch (error) {
      throw error;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      return _userFromFirebaseUser(user!);
    } catch (error) {
      throw error;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw error;
    }
  }
}
