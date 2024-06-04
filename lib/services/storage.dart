import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;

  List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isUploading = false;

  List<String> get imageUrls => _imageUrls;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  Future<void> fetchImages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ListResult result = await firebaseStorage.ref('uploaded_images/').listAll();
      final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));
      _imageUrls = urls;
    } catch (e) {
      debugPrint("Error fetching images: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteImages(String imageUrl) async {
    try {
      _imageUrls.remove(imageUrl);
      final String path = extractPathFromUrl(imageUrl);
      await firebaseStorage.ref(path).delete();
    } catch (e) {
      debugPrint("Error deleting image: $e");
    } finally {
      notifyListeners();
    }
  }

  String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);
    String encodePath = uri.pathSegments.last;
    return Uri.decodeComponent(encodePath);
  }

  Future<String?> uploadImage(File file) async {
    _isUploading = true;
    notifyListeners();

    try {
      String filePath = 'uploaded_images/${DateTime.now().millisecondsSinceEpoch}.png';
      await firebaseStorage.ref(filePath).putFile(file);
      String downloadUrl = await firebaseStorage.ref(filePath).getDownloadURL();
      _imageUrls.add(downloadUrl);
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
