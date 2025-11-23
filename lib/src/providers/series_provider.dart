import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/series_repository.dart';
import '../utils/storage_utils.dart';

class SeriesProvider with ChangeNotifier {
  final SeriesRepository _seriesRepository = SeriesRepository();

  List<MediaItem> _series = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedGenreId = 0;
  FilterType _selectedFilter = FilterType.defaultFilter;

  List<MediaItem> get series => _series;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get selectedGenreId => _selectedGenreId;
  FilterType get selectedFilter => _selectedFilter;

  Future<void> loadSeries({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (refresh) {
        _series = [];
        _currentPage = 0;
        _hasMore = true;
      }

      if (!_hasMore) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newSeries = await _seriesRepository.getSeries(
        page: _currentPage,
        genreId: _selectedGenreId,
        filterType: _selectedFilter,
      );

      // Filter out series with Farsi/Arabic titles
      final filteredSeries = newSeries
          .where((series) => !containsFarsiOrArabic(series.title))
          .toList();

      if (filteredSeries.isEmpty && newSeries.isNotEmpty) {
        // If all series were filtered out, try to load more
        _currentPage++;
        _isLoading = false;
        notifyListeners();
        // Load more series recursively
        await loadSeries();
        return;
      }

      if (newSeries.isEmpty) {
        _hasMore = false;
      } else {
        _series.addAll(filteredSeries);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSeries() async {
    await loadSeries(refresh: true);
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    refreshSeries();
  }

  void selectFilter(FilterType filter) {
    _selectedFilter = filter;
    refreshSeries();
  }

  void resetFilters() {
    _selectedGenreId = 0;
    _selectedFilter = FilterType.defaultFilter;
    refreshSeries();
  }
}
