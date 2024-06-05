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
  bool _isDeleting = false;
  bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          displayName = userDoc.data()?['displayName'];
        });
      }
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
              if (widget.data['imagePath'] != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 200, // Adjust the height as needed
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.data['imagePath'],
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              _isImageLoading = false;
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes!)
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    ),
                    if (_isImageLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
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
                    if (mounted) {
                      Navigator.of(context).pop();
                      widget.onMarkerUpdated();
                    }
                  },
                ),
              const SizedBox(height: 8),
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
                      if (mounted) {
                        Navigator.of(context).pop();
                        widget.onMarkerUpdated();
                      }
                    }
                  },
                ),
              const SizedBox(height: 16),
              if (userId == widget.data['userId'])
                ElevatedButton(
                  onPressed: _isDeleting ? null : _confirmDelete,
                  child: _isDeleting ? const CircularProgressIndicator() : const Text('Excluir Peak'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmação de Exclusão'),
            content: const Text('Tem certeza de que deseja excluir este Peak?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  _deletePeak();
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _deletePeak() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await firestoreService.deleteData(widget.peakId);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMarkerUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir Peak: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
