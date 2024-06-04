import 'package:flutter/material.dart';
import 'filter_peaks_modal.dart';
import 'search_peaks_modal.dart';

class SearchAndFilterBar extends StatelessWidget {
  final Function(String? difficulty, String? popularity) onApplyFilters;
  final Function(String name) onSearch;

  const SearchAndFilterBar({
    super.key,
    required this.onApplyFilters,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar Peaks',
                        border: InputBorder.none,
                      ),
                      onSubmitted: onSearch,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return SearchPeaksModal(onSearch: onSearch);
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return FilterPeaksModal(onApplyFilters: onApplyFilters);
                          },
                        );
                    },
                  ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
