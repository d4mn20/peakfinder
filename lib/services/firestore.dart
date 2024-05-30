import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final String collectionName;
  late final CollectionReference collection;

  FirestoreService(this.collectionName) {
    collection = FirebaseFirestore.instance.collection(collectionName);
  }

  // CREATE
  Future<void> addData(Map<String, dynamic> data) async {
    try {
      await collection.add(data);
    } catch (e) {
      rethrow;
    }
  }

  // READ
  Stream<QuerySnapshot> getSnapshot() {
    return collection.snapshots();
  }

  Future<List<QueryDocumentSnapshot>> getAllData() async {
    try {
      QuerySnapshot querySnapshot = await collection.get();
      return querySnapshot.docs;
    } catch (e) {
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateData(String id, Map<String, dynamic> data) async {
    try {
      await collection.doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteData(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
