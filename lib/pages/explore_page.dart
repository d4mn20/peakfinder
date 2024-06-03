import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peakfinder/components/my_dropdown_button.dart';
import 'package:peakfinder/services/firestore.dart';
import 'package:provider/provider.dart';
import '../components/my_app_bar.dart';
import '../components/my_drawer.dart';
import '../components/my_textfield.dart';
import '../components/my_button.dart';
import '../services/storage.dart';
import '../services/image_path_controller.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentP;
  LatLng? _selectedLocation;
  bool _isActionEnabled = false;
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> _markers = {};
  BitmapDescriptor? _flagIcon;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    fetchMarkersFromFirestore();
    loadCustomMarkerIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MyAppBar(
        title: "E X P L O R A R",
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddButtonPressed,
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: _currentP == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) => _mapController.complete(controller),
              initialCameraPosition: CameraPosition(
                target: _currentP!,
                zoom: 13,
              ),
              markers: _markers,
              polylines: Set<Polyline>.of(polylines.values),
              onTap: _onMapTapped,
            ),
    );
  }

  void _onAddButtonPressed() {
    setState(() {
      _isActionEnabled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Toque no mapa para selecionar uma localização")),
    );
  }

  void _onMapTapped(LatLng position) {
    if (_isActionEnabled) {
      setState(() {
        _selectedLocation = position;
        _isActionEnabled = false;
      });
      _showAddPeakModal();
    }
  }

  void _showAddPeakModal() {
    String? selectedDifficulty;
    final List<String> difficultyOptions = [
      'I', 'Isup', 'II', 'IIsup', 'III', 'IIIsup', 'IV', 'IVsup', 'V', 'VI',
      'VI/VI+', 'VIsup/VI+', 'VIsup', '7a', '7b', '7c', '8a', '8b', '8c', '9a',
      '9b', '9c', '10a', '10b', '10c', '11a', '11b', '11c', '12a', '12b', '12c',
    ];

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final protectionsController = TextEditingController();
    final conquerorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
                          imagePathController.imagePath == null
                              ? const Text('Nenhuma imagem selecionada')
                              : Image.network(imagePathController.imagePath!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                              if (image != null) {
                                String? imagePath = await Provider.of<StorageService>(context, listen: false)
                                    .uploadImage(File(image.path));
                                if (imagePath != null) {
                                  imagePathController.setImagePath(imagePath);
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
                        onTap: () async {
                          try {
                            final location = _selectedLocation != null
                                ? {
                                    'latitude': _selectedLocation!.latitude,
                                    'longitude': _selectedLocation!.longitude,
                                  }
                                : null;

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

                            final userId = FirebaseAuth.instance.currentUser?.uid; // Obtém o userId

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
                            Navigator.of(context).pop(); // Fechar o modal
                            fetchMarkersFromFirestore(); // Refresh markers
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save data: $e')),
                            );
                          }
                        },
                        text: "Salvar",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> getLocationUpdates() async {
    try {
      bool serviceEnabled = await _locationController.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationController.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _locationController.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationController.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      _locationController.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          setState(() {
            _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _markers.add(
              Marker(
                markerId: const MarkerId("_currentLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: _currentP!,
                infoWindow: const InfoWindow(title: "Current Location"),
              ),
            );
          });
        }
      });
    } catch (e) {
      debugPrint('Error getting location updates: $e');
    }
  }

  Future<void> loadCustomMarkerIcon() async {
    _flagIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'lib/images/flag_icon.png',
    );
  }

  Future<void> fetchMarkersFromFirestore() async {
    try {
      List<QueryDocumentSnapshot> documents = await firestoreService.getAllData();
      Set<Marker> fetchedMarkers = documents.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null && data['location'] is Map<String, dynamic>) {
          Map<String, dynamic> locationData = data['location'] as Map<String, dynamic>;
          LatLng position = LatLng(locationData['latitude'], locationData['longitude']);
          return Marker(
            markerId: MarkerId(doc.id),
            position: position,
            icon: _flagIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: data['name'],
              snippet: data['description'],
            ),
            onTap: () {
              _showMarkerInfoBottomSheet(data, doc.id);
            },
          );
        } else {
          return null; // Return null if location data is invalid
        }
      }).where((marker) => marker != null).cast<Marker>().toSet();

      setState(() {
        _markers = fetchedMarkers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load markers: $e')),
      );
    }
  }

  void _showMarkerInfoBottomSheet(Map<String, dynamic> data, String peakId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal ocupe mais espaço
      builder: (BuildContext context) {
        return FractionallySizedBox(
          widthFactor: 1,
          heightFactor: 0.75, // Define a altura do modal como 90% da altura da tela
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Conquistador:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${data['conqueror'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${data['description'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  const Text('Proteções:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${data['protection'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  const Text('Dificuldade:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${data['difficulty'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  if (data['imagePath'] != null)
                    Image.network(
                      data['imagePath'],
                      fit: BoxFit.fitWidth,
                    ),
                  const SizedBox(height: 8),
                  if (userId != null)
                    IconButton(
                      icon: Icon(
                        data['likes'] != null && (data['likes'] as List).contains(userId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      onPressed: () async {
                        await firestoreService.toggleLike(peakId, userId);
                        Navigator.of(context).pop();
                        fetchMarkersFromFirestore();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
