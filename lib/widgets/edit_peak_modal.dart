import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:peakfinder/widgets/my_button.dart';
import 'package:peakfinder/widgets/my_textfield.dart';
import 'package:peakfinder/widgets/my_dropdown_button.dart';
import 'package:peakfinder/services/firestore.dart';
import 'package:peakfinder/services/image_path_controller.dart';
import 'package:peakfinder/services/storage.dart';

class EditPeakModal extends StatefulWidget {
  final Map<String, dynamic> peakData;
  final String peakId;
  final VoidCallback onPeakUpdated;

  const EditPeakModal({
    Key? key,
    required this.peakData,
    required this.peakId,
    required this.onPeakUpdated,
  }) : super(key: key);

  @override
  EditPeakModalState createState() => EditPeakModalState();
}

class EditPeakModalState extends State<EditPeakModal> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController protectionsController = TextEditingController();
  final TextEditingController conquerorController = TextEditingController();
  String? selectedDifficulty;
  String? imagePath;
  final List<String> difficultyOptions = [
    'I', 'Isup', 'II', 'IIsup', 'III', 'IIIsup', 'IV', 'IVsup', 'V', 'VI',
    'VI/VI+', 'VIsup/VI+', 'VIsup', '7a', '7b', '7c', '8a', '8b', '8c', '9a',
    '9b', '9c', '10a', '10b', '10c', '11a', '11b', '11c', '12a', '12b', '12c',
  ];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.peakData['name'];
    descriptionController.text = widget.peakData['description'];
    protectionsController.text = widget.peakData['protections'];
    conquerorController.text = widget.peakData['conqueror'];
    selectedDifficulty = widget.peakData['difficulty'];
    imagePath = widget.peakData['imagePath'];
  }

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
                "Editar Peak",
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
              MyTextField(
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
                      imagePath == null
                          ? const Text('Nenhuma imagem selecionada')
                          : Image.network(imagePath!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                          if (image != null) {
                            String? newPath = await Provider.of<StorageService>(context, listen: false)
                                .uploadImage(File(image.path));
                            if (newPath != null) {
                              setState(() {
                                imagePath = newPath;
                              });
                            }
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
                    onTap: _editPeak,
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

  Future<void> _editPeak() async {
    try {
      if (nameController.text.isEmpty ||
          conquerorController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          protectionsController.text.isEmpty ||
          selectedDifficulty == null ||
          imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos')),
        );
        return;
      }

      await firestoreService.updateData(widget.peakId, {
        "name": nameController.text,
        "description": descriptionController.text,
        "protections": protectionsController.text,
        "conqueror": conquerorController.text,
        "difficulty": selectedDifficulty,
        "imagePath": imagePath,
      });
      Navigator.of(context).pop();
      widget.onPeakUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update data: $e')),
      );
    }
  }
}
