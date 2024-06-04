import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:peakfinder/screens/explore_page.dart';
import 'package:peakfinder/widgets/my_app_bar.dart';
import 'package:peakfinder/widgets/my_drawer.dart';
import 'package:peakfinder/services/firestore.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const MyAppBar(
        title: "F A V O R I T O S",
        actions: [],
      ),
      drawer: const MyDrawer(),
      body: userId == null
          ? const Center(child: Text("Usuário não logado"))
          : StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getSnapshot(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final favoritePeaks = snapshot.data!.docs.where((doc) {
                  return (doc.data() as Map<String, dynamic>)['likes'] != null &&
                      (doc.data() as Map<String, dynamic>)['likes'].contains(userId);
                }).toList();

                if (favoritePeaks.isEmpty) {
                  return const Center(child: Text("Você ainda não favoritou nenhum peak."));
                }

                return ListView.builder(
                  itemCount: favoritePeaks.length,
                  itemBuilder: (context, index) {
                    final data = favoritePeaks[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(data['name']),
                          subtitle: Text(data['description']),
                          onTap: () {
                            final locationData = data['location'] as Map<String, dynamic>;
                            final LatLng position = LatLng(locationData['latitude'], locationData['longitude']);
                            _navigateToExplorePage(context, data, favoritePeaks[index].id, position);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite),
                            onPressed: () async {
                              await firestoreService.toggleLike(favoritePeaks[index].id, userId!);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _navigateToExplorePage(BuildContext context, Map<String, dynamic> data, String peakId, LatLng position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExplorePage(
          initialData: data,
          initialPeakId: peakId,
          initialPosition: position,
        ),
      ),
    );
  }
}
