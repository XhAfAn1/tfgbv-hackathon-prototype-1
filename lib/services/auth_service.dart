import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInit = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInit => _isInit; // To show a loading screen while checking initial state

  AuthService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _isLoading = true;
      notifyListeners();

      if (user == null) {
        _currentUser = null;
      } else {
        await _fetchUserDetails(user.uid);
      }

      _isLoading = false;
      _isInit = true; // Mark initialized after fetching
      notifyListeners();
    });
  }

  Future<void> _fetchUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Let authStateChanges handle the rest
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signup(String email, String password, String name, bool isNgo) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );

      final role = isNgo ? 'ngo' : 'victim';
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        role: role,
        name: name,
      );

      // Save user to Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      
      // Let authStateChanges handle the rest
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
