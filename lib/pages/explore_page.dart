import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
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

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  LatLng? _currentP;
  LatLng? _selectedLocation;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
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
            onPressed: _onAddMarkerButtonPressed,
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: _currentP == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              initialCameraPosition: CameraPosition(
                target: _currentP!,
                zoom: 13,
              ),
              markers: _createMarkers(),
              polylines: Set<Polyline>.of(polylines.values),
              onTap: _onMapTapped,
            ),
    );
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    if (_currentP != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("_currentLocation"),
          icon: BitmapDescriptor.defaultMarker,
          position: _currentP!,
        ),
      );
    }

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("_selectedLocation"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: _selectedLocation!,
        ),
      );
    }

    return markers;
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
    setState(() {
      _selectedLocation = position;
    });

    _showLocationInfoBottomSheet();
  }

  void _showLocationInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o BottomSheet use o tamanho necessário para o conteúdo
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta a altura do teclado
          ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Cor do botão Cancelar
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o BottomSheet
                        },
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String name = nameController.text;
                          // Adicione a lógica para salvar ou utilizar as informações inseridas
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Nome: $name, Localização: $_selectedLocation")),
                          );
                          // firestoreService.addData({
                          //     "name": name,
                          //     "location": _selectedLocation,
                          //   }, 
                          // "peaks");
                          firestoreService.addData({"name": name});
                          Navigator.of(context).pop(); // Fecha o BottomSheet
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

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
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
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentP!);
        });
      }
    });
  }
}
