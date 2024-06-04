import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/my_app_bar.dart';
import '../widgets/my_drawer.dart';
import '../widgets/edit_peak_modal.dart';
import '../services/firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService firestoreService = FirestoreService("peaks"); 
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const MyAppBar(title: "P E R F I L", actions: []),
      drawer: const MyDrawer(),
      body: currentUser == null
          ? const Center(child: Text("Usuário não logado"))
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getUserDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  Map<String, dynamic>? user = snapshot.data!.data();
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getSnapshot(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userPeaks = snapshot.data!.docs.where((doc) => 
                          (doc.data() as Map<String, dynamic>)['userId'] == currentUser!.uid
                      ).toList();

                      return ListView(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.all(25),
                                  child: const Icon(Icons.person),
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  user!['displayName'],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  user['email'],
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          if (userPeaks.isEmpty)
                            const Center(child: Text("Você ainda não criou nenhum peak."))
                          else
                            ...userPeaks.map((peak) {
                              Map<String, dynamic> peakData = peak.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(peakData['name']),
                                    subtitle: Text(peakData['description']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showEditPeakModal(peak.id, peakData),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () async {
                                            await firestoreService.deleteData(peak.id);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      );
                    },
                  );
                } else {
                  return const Text("Sem dados");
                }
              },
            ),
    );
  }

  void _showEditPeakModal(String peakId, Map<String, dynamic> peakData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EditPeakModal(
          peakData: peakData,
          peakId: peakId,
          onPeakUpdated: () => setState(() {}),
        );
      },
    );
  }
}
