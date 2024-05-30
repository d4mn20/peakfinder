import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

 final String collectionName;
  CollectionReference collection;

  FirestoreService(this.collectionName) : collection = FirebaseFirestore.instance.collection(collectionName) {
    collection = FirebaseFirestore.instance.collection(collectionName);
  }
  // CREATE
  Future<void> addData(Map<String, dynamic> data) {
    return collection.add(data);
  }

  //READ
  Stream<QuerySnapshot> getSnapshot() {
    return collection.snapshots();
  }

  //UPDATE
  Future<void> updateData(String id, Map<String, dynamic> data) {
    return collection.doc(id).update(data);
  }

  //DELETE
  Future<void> deleteData(String id) {
    return collection.doc(id).delete();
  }
}