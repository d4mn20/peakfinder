import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> saveUserToFirestore(User user, [String? username]) async {
    final userDoc = usersCollection.doc(user.uid);

    // Verifique se o usuário já existe
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': username ?? user.displayName,
        // Adicione outros campos conforme necessário
      });
    }
  }
}
