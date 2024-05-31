import 'package:flutter/material.dart';

class ImagePathController extends ChangeNotifier {
  String? _imagePath;

  String? get imagePath => _imagePath;

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void clearImagePath() {
    _imagePath = null;
    notifyListeners();
  }
}
