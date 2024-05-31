import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService with ChangeNotifier {
  // firebase storage
  final firebaseStorage = FirebaseStorage.instance;

  //images are stored in firebase as download URLs
  List<String> _imageUrls = [];

  // loading status
  bool _isLoading = false; 

  // uploading status
  bool _isUploading = false;

  // Getters
  List<String> get imageUrls => _imageUrls;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  // READ Images
  Future<void> fetchImages() async {
    // start loading...
    final ListResult result = await firebaseStorage.ref('uploaded_images/').listAll();

    // get the download URLs for each image
    final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));

    // update URLs
    _imageUrls = urls;

    // loading finished...
    _isLoading = false;

    // update UI
    notifyListeners();
  }

  // DELETE Image
  // - images are stored as download URLs. 
  // E.g: https://firebasestorage.googleapis.com/v0/b/fir-master.../uploaded_images/image_name.png
  // - in order to delete, we need to know only the path of this image store in firebase
  Future<void> deleteImages(String imageUrl) async {
    try {
      // remove from local list
      _imageUrls.remove(imageUrl);

      // get path name and delete from firebase
      final String path = extractPathFromUrl(imageUrl);
      await firebaseStorage.ref(path).delete();
    } 

    // handle any errors
    catch (e) {
      print("Error deleting image: $e");
    }

    // update UI
    notifyListeners();
  }

  String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);

    // extracting the part of the url we need
    String encodePath = uri.pathSegments.last;

    // url decoding the path
    return Uri.decodeComponent(encodePath);
  }

  // UPLOAD Image
  Future<String?> uploadImage(File file) async {
    _isUploading = true;
    notifyListeners();

    try {
      // Define the path in storage
      String filePath = 'uploaded_images/${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload the file to Firebase Storage
      await firebaseStorage.ref(filePath).putFile(file);

      // After uploading, fetch the download URL
      String downloadUrl = await firebaseStorage.ref(filePath).getDownloadURL();

      // Update the image URLs list and UI
      _imageUrls.add(downloadUrl);
      notifyListeners();

      return downloadUrl; // Return the download URL
    } catch (e) {
      print("Error uploading...$e");
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}