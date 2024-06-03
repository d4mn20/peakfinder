import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:peakfinder/services/firestore_user_service.dart'; // Importa o FirestoreUserService

class AuthService {
  // instance of auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreUserService _firestoreUserService = FirestoreUserService(); // Instancia o FirestoreUserService

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Email sign in
  Future<UserCredential> signInWithEmailAndPassword(String email, password) async {
    try {
      // sign user in
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
            email: email, 
            password: password
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Email sign up
  Future<UserCredential> signUpWithEmailAndPassword(String email, password) async {
    try {
      // sign user in
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
            email: email, 
            password: password
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
      try {
    await _firebaseAuth.signOut();
    print("User signed out successfully");
  } catch (e) {
    print("Error signing out: $e");
  }
  }

  // Google sign in
  Future<UserCredential> signInWithGoogle() async {
    // begin interactive sign in process
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // users cancels google sign in pop up screen
    if (googleUser == null) return Future.error('Google Sign In aborted');

    // obtain auth details from request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // finally, sign in
    UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

    await _firestoreUserService.saveUserToFirestore(userCredential.user!, googleUser.displayName);
    
    return userCredential;
  }

  // possible error messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'Exception: wrong-password':
        return 'A senha está incorreta. Por favor tente novamente.';
      case 'Exception: user-not-found':
        return 'Nenhum usuário cadastrado com esse email. Por favor tente novamente.';
      case 'Exception: invalid-email':
        return 'Este email não existe.';
      default:
        return 'Erro inesperado. Por favor tente novamente mais tarde.';
    }
  }
}