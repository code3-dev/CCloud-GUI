import 'package:flutter/material.dart';
import '../models/poster.dart';
import '../repositories/search_repository.dart';
import '../utils/storage_utils.dart';

class SearchProvider with ChangeNotifier {
  final SearchRepository _searchRepository = SearchRepository();

  List<Poster> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _hasSearched = false;

  List<Poster> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get hasSearched => _hasSearched;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    if (!_hasSearched) {
      _searchResults = [];
      notifyListeners();
    }
  }

  void triggerSearch() {
    if (_searchQuery.isNotEmpty) {
      _hasSearched = true;
      search(_searchQuery);
    }
  }

  Future<void> search(String query) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _searchRepository.search(query);

      // Filter out search results with Farsi/Arabic titles
      final filteredPosters = result.posters
          .where((poster) => !containsFarsiOrArabic(poster.title))
          .toList();

      _searchResults = filteredPosters;
    } catch (e) {
      print('Error in SearchProvider.search: $e');
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _errorMessage = null;
    _hasSearched = false;
    notifyListeners();
  }
}
