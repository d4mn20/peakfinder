import 'package:flutter/material.dart';

class SearchPeaksModal extends StatefulWidget {
  final Function(String name) onSearch;

  const SearchPeaksModal({super.key, required this.onSearch});

  @override
  SearchPeaksModalState createState() => SearchPeaksModalState();
}

class SearchPeaksModalState extends State<SearchPeaksModal> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Busca'),
      content: TextField(
        controller: searchController,
        decoration: const InputDecoration(hintText: 'Digite o nome do Peak'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSearch(searchController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
