import 'package:flutter/material.dart';
import 'filter_peaks_modal.dart';
import 'search_peaks_modal.dart';

class SearchAndFilterBar extends StatelessWidget {
  final Function(String? difficulty, String? popularity) onApplyFilters;
  final Function(String name) onSearch;
  final VoidCallback onCurrentLocation;

  const SearchAndFilterBar({
    super.key,
    required this.onApplyFilters,
    required this.onSearch,
    required this.onCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8, // Adjust this value if needed
      right: 8,
      child: Column(
        children: [
          FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            heroTag: 'search',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchPeaksModal(onSearch: onSearch);
                },
              );
            },
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            heroTag: 'filter',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FilterPeaksModal(onApplyFilters: onApplyFilters);
                },
              );
            },
            child: const Icon(Icons.filter_list),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            heroTag: 'current location',
            onPressed: onCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}