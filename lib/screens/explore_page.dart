import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peakfinder/services/firestore.dart';
import 'package:peakfinder/widgets/my_app_bar.dart';
import 'package:peakfinder/widgets/my_drawer.dart';
import 'package:peakfinder/widgets/add_peak_modal.dart';
import 'package:peakfinder/widgets//marker_info_modal.dart';
import 'package:peakfinder/widgets/search_and_filter_bar.dart';

class ExplorePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? initialPeakId;
  final LatLng? initialPosition;

  const ExplorePage({super.key, this.initialData, this.initialPeakId, this.initialPosition});

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
  bool _isLoading = false;

  String? selectedDifficulty;
  String? selectedPopularity;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    fetchMarkersFromFirestore();
    loadCustomMarkerIcon();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialData != null && widget.initialPeakId != null) {
        _showMarkerInfoModal(widget.initialData!, widget.initialPeakId!);
      }

      if (widget.initialPosition != null) {
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLng(widget.initialPosition!));
      }
    });
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
      body: Stack(
        children: [
          _currentP == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) => _mapController.complete(controller),
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPosition ?? _currentP!,
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: Set<Polyline>.of(polylines.values),
                  onTap: _onMapTapped,
                ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          SearchAndFilterBar(
            onApplyFilters: _applyFilters,
            onSearch: _searchPeakByName,
            onCurrentLocation: _goToCurrentLocation,
          ),
        ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddPeakModal(
          selectedLocation: _selectedLocation!,
          onPeakAdded: fetchMarkersFromFirestore,
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
    setState(() {
      _isLoading = true;
    });

    try {
      List<QueryDocumentSnapshot> documents = await firestoreService.getAllData();
      Set<Marker> fetchedMarkers = documents.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (_applyFiltersData(data)) {
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
                onTap: () {
                  _showMarkerInfoModal(data, doc.id);
                },
              ),
            );
          }
        }
        return null; // Return null if location data is invalid or filter does not match
      }).where((marker) => marker != null).cast<Marker>().toSet();

      setState(() {
        _markers = fetchedMarkers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load markers: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _applyFiltersData(Map<String, dynamic> data) {
    bool matchesDifficulty = selectedDifficulty == null || data['difficulty'] == selectedDifficulty;
    bool matchesPopularity = selectedPopularity == null || _getPopularity(data) == selectedPopularity;
    return matchesDifficulty && matchesPopularity;
  }

  void _applyFilters(String? difficulty, String? popularity) {
    setState(() {
      selectedDifficulty = difficulty;
      selectedPopularity = popularity;
      fetchMarkersFromFirestore();
    });
  }

  String _getPopularity(Map<String, dynamic> data) {
    int likes = (data['likes'] ?? []).length;
    if (likes > 50) return 'Muito Popular';
    if (likes > 20) return 'Popular';
    return 'Pouco Popular';
  }

  void _showMarkerInfoModal(Map<String, dynamic> data, String peakId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MarkerInfoModal(
          data: data,
          peakId: peakId,
          onMarkerUpdated: fetchMarkersFromFirestore,
        );
      },
    );
  }

  void _searchPeakByName(String name) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<QueryDocumentSnapshot> documents = await firestoreService.getAllData();
      QueryDocumentSnapshot? result;

      for (var doc in documents) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['name'].toString().toLowerCase() == name.toLowerCase()) {
          result = doc;
          break;
        }
      }

      if (result != null) {
        Map<String, dynamic> data = result.data() as Map<String, dynamic>;
        Map<String, dynamic> locationData = data['location'] as Map<String, dynamic>;
        LatLng position = LatLng(locationData['latitude'], locationData['longitude']);
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLng(position));
        _showMarkerInfoModal(data, result.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum Peak encontrado com esse nome')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na busca: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentP != null) {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(_currentP!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização atual não disponível')),
      );
    }
  }
}
