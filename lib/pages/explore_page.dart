import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peakfinder/components/my_dropdown_button.dart';
import 'package:peakfinder/services/firestore.dart';
import '../components/my_app_bar.dart';
import '../components/my_drawer.dart';

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

  Future<void> loadCustomMarkerIcon() async {
    _flagIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'lib/images/flag_icon.png',
    );
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
            onPressed: () {
              setState(() {
                _isActionEnabled = !_isActionEnabled;
              });
              _onAddMarkerButtonPressed();
            },
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

  void _onAddMarkerButtonPressed() {
    setState(() {
      _selectedLocation = null; // Reset selected location
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tap on the map to select a location")),
    );
  }

  void _onMapTapped(LatLng position) {
    if (_isActionEnabled) {
      setState(() {
        _selectedLocation = position;
      });
      _addNewPeak();
    }
  }

  void _addNewPeak() {
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
                  Text(
                    "Localização Selecionada: (${_selectedLocation?.latitude}, ${_selectedLocation?.longitude})",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: conquerorController,
                    decoration: const InputDecoration(
                      labelText: "Conquistador",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Descrição",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: protectionsController,
                    decoration: const InputDecoration(
                      labelText: "Proteções",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MyDropdownButton<String>(
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final location = _selectedLocation != null
                                ? {
                                    'latitude': _selectedLocation!.latitude,
                                    'longitude': _selectedLocation!.longitude,
                                  }
                                : null;

                            await firestoreService.addData({
                              "name": nameController.text,
                              "location": location,
                              "description": descriptionController.text,
                              "protections": protectionsController.text,
                              "conqueror": conquerorController.text,
                              "difficulty": selectedDifficulty,
                            });
                            setState(() {
                              _isActionEnabled = false;
                            });
                            Navigator.of(context).pop();
                            fetchMarkersFromFirestore(); // Refresh markers
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save data: $e')),
                            );
                          }
                        },
                        child: const Text("Salvar"),
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
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
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
}
