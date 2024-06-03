import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/my_app_bar.dart';
import '../components/my_drawer.dart';
import '../services/firestore.dart';

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
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(data['description']),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () async {
                          await firestoreService.toggleLike(favoritePeaks[index].id, userId!);
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
