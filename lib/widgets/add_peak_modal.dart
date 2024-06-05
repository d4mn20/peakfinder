import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:peakfinder/widgets/my_button.dart';
import 'package:peakfinder/widgets/my_textfield.dart';
import 'package:peakfinder/widgets/my_multi_textfield.dart';
import 'package:peakfinder/widgets/my_dropdown_button.dart';
import 'package:peakfinder/services/firestore.dart';
import 'package:peakfinder/services/image_path_controller.dart';
import 'package:peakfinder/services/storage.dart';

class AddPeakModal extends StatefulWidget {
  final LatLng selectedLocation;
  final VoidCallback onPeakAdded;

  const AddPeakModal({
    Key? key,
    required this.selectedLocation,
    required this.onPeakAdded,
  }) : super(key: key);

  @override
  AddPeakModalState createState() => AddPeakModalState();
}

class AddPeakModalState extends State<AddPeakModal> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController protectionsController = TextEditingController();
  final TextEditingController conquerorController = TextEditingController();
  String? selectedDifficulty;
  bool _isLoadingImage = false;
  final List<String> difficultyOptions = [
    'I', 'Isup', 'II', 'IIsup', 'III', 'IIIsup', 'IV', 'IVsup', 'V', 'VI',
    'VI/VI+', 'VIsup/VI+', 'VIsup', '7a', '7b', '7c', '8a', '8b', '8c', '9a',
    '9b', '9c', '10a', '10b', '10c', '11a', '11b', '11c', '12a', '12b', '12c',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Adicione seu Peak",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              MyTextField(
                controller: nameController,
                hintText: 'Nome',
                obscureText: false,
              ),
              const SizedBox(height: 16),
              MyTextField(
                controller: conquerorController,
                hintText: 'Conquistador',
                obscureText: false,
              ),
              const SizedBox(height: 16),
              MyMultiTextField(
                controller: descriptionController,
                hintText: 'Descrição',
                obscureText: false,
              ),
              const SizedBox(height: 16),
              MyTextField(
                controller: protectionsController,
                hintText: 'Proteções',
                obscureText: false,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return MyDropdownButton<String>(
                    hint: 'Dificuldade',
                    value: selectedDifficulty,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDifficulty = newValue;
                      });
                    },
                    items: difficultyOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer<ImagePathController>(
                builder: (context, imagePathController, child) {
                  return Column(
                    children: [
                      _isLoadingImage
                          ? const CircularProgressIndicator()
                          : imagePathController.imagePath == null
                              ? const Text('Nenhuma imagem selecionada')
                              : Image.network(imagePathController.imagePath!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoadingImage ? null : () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                          if (image != null) {
                            setState(() {
                              _isLoadingImage = true;
                            });

                            String? imagePath = await Provider.of<StorageService>(context, listen: false)
                                .uploadImage(File(image.path));

                            if (imagePath != null) {
                              imagePathController.setImagePath(imagePath);
                            }

                            setState(() {
                              _isLoadingImage = false;
                            });
                          }
                        },
                        child: const Text('Selecionar Imagem'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyButton(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    text: "Cancelar",
                  ),
                  MyButton(
                    onTap: _addPeak,
                    text: "Salvar",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPeak() async {
    try {
      final location = {
        'latitude': widget.selectedLocation.latitude,
        'longitude': widget.selectedLocation.longitude,
      };

      if (nameController.text.isEmpty ||
          conquerorController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          protectionsController.text.isEmpty ||
          selectedDifficulty == null ||
          Provider.of<ImagePathController>(context, listen: false).imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos')),
        );
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await firestoreService.addData({
        "name": nameController.text,
        "location": location,
        "description": descriptionController.text,
        "protections": protectionsController.text,
        "conqueror": conquerorController.text,
        "difficulty": selectedDifficulty,
        "imagePath": Provider.of<ImagePathController>(context, listen: false).imagePath,
      }, userId);
      Navigator.of(context).pop();
      widget.onPeakAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }
}
