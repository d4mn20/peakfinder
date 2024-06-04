import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peakfinder/services/firestore.dart';

class MarkerInfoModal extends StatefulWidget {
  final Map<String, dynamic> data;
  final String peakId;
  final VoidCallback onMarkerUpdated;

  const MarkerInfoModal({
    Key? key,
    required this.data,
    required this.peakId,
    required this.onMarkerUpdated,
  }) : super(key: key);

  @override
  MarkerInfoModalState createState() => MarkerInfoModalState();
}

class MarkerInfoModalState extends State<MarkerInfoModal> {
  final FirestoreService firestoreService = FirestoreService("peaks");
  final TextEditingController commentController = TextEditingController();
  String? displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        displayName = userDoc.data()?['displayName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return FractionallySizedBox(
      widthFactor: 1,
      heightFactor: 0.75,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data['name'] ?? 'No Name',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Conquistador:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.data['conqueror'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.data['description'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              const Text('Proteções:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.data['protections'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              const Text('Dificuldade:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.data['difficulty'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              if (widget.data['imagePath'] != null)
                Image.network(
                  widget.data['imagePath'],
                  fit: BoxFit.fitWidth,
                ),
              const SizedBox(height: 8),
              if (userId != null)
                IconButton(
                  icon: Icon(
                    widget.data['likes'] != null && (widget.data['likes'] as List).contains(userId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: () async {
                    await firestoreService.toggleLike(widget.peakId, userId);
                    Navigator.of(context).pop();
                    widget.onMarkerUpdated();
                  },
                ),
              const SizedBox(height: 16),
              const Text('Comentários:', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: (widget.data['comments'] ?? []).map<Widget>((comment) {
                  return ListTile(
                    title: Text(comment['user']),
                    subtitle: Text(comment['text']),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (userId != null)
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Adicionar um comentário...',
                  ),
                  onSubmitted: (text) async {
                    if (text.isNotEmpty && displayName != null) {
                      List<dynamic> comments = widget.data['comments'] ?? [];
                      comments.add({'user': displayName, 'text': text});
                      await firestoreService.updateData(widget.peakId, {'comments': comments});
                      Navigator.of(context).pop();
                      widget.onMarkerUpdated();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
