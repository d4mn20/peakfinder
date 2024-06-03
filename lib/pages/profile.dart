import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/my_app_bar.dart';
import '../components/my_drawer.dart';
import '../services/firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const MyAppBar(
        title: "P E R F I L",
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

                final userPeaks = snapshot.data!.docs.where((doc) {
                  return (doc.data() as Map<String, dynamic>)['userId'] == userId;
                }).toList();

                if (userPeaks.isEmpty) {
                  return const Center(child: Text("Você ainda não criou nenhum peak."));
                }

                return ListView.builder(
                  itemCount: userPeaks.length,
                  itemBuilder: (context, index) {
                    final data = userPeaks[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(data['description']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await firestoreService.deleteData(userPeaks[index].id);
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
