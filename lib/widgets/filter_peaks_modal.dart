import 'package:flutter/material.dart';

class FilterPeaksModal extends StatefulWidget {
  final Function(String? difficulty, String? popularity) onApplyFilters;

  const FilterPeaksModal({super.key, required this.onApplyFilters});

  @override
  FilterPeaksModalState createState() => FilterPeaksModalState();
}

class FilterPeaksModalState extends State<FilterPeaksModal> {
  String? selectedDifficulty;
  String? selectedPopularity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            hint: const Text('Selecione a Dificuldade'),
            value: selectedDifficulty,
            onChanged: (String? newValue) {
              setState(() {
                selectedDifficulty = newValue;
              });
            },
            items: [
              'I', 'Isup', 'II', 'IIsup', 'III', 'IIIsup', 'IV', 'IVsup', 'V', 'VI',
              'VI/VI+', 'VIsup/VI+', 'VIsup', '7a', '7b', '7c', '8a', '8b', '8c', '9a',
              '9b', '9c', '10a', '10b', '10c', '11a', '11b', '11c', '12a', '12b', '12c',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            hint: const Text('Selecione a Popularidade'),
            value: selectedPopularity,
            onChanged: (String? newValue) {
              setState(() {
                selectedPopularity = newValue;
              });
            },
            items: [
              'Pouco Popular', 'Popular', 'Muito Popular',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onApplyFilters(selectedDifficulty, selectedPopularity);
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar Filtros'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              selectedDifficulty = null;
              selectedPopularity = null;
            });
            widget.onApplyFilters(null, null);
            Navigator.of(context).pop();
          },
          child: const Text('Limpar Filtros'),
        ),
      ],
    );
  }
}
