import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/movie_repository.dart';
import '../utils/storage_utils.dart';

class MovieProvider with ChangeNotifier {
  final MovieRepository _movieRepository = MovieRepository();

  List<MediaItem> _movies = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMore = true;
  int _selectedGenreId = 0;
  FilterType _selectedFilter = FilterType.defaultFilter;

  List<MediaItem> get movies => _movies;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get selectedGenreId => _selectedGenreId;
  FilterType get selectedFilter => _selectedFilter;

  Future<void> loadMovies({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (refresh) {
        _movies = [];
        _currentPage = 0;
        _hasMore = true;
      }

      if (!_hasMore) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newMovies = await _movieRepository.getMovies(
        page: _currentPage,
        genreId: _selectedGenreId,
        filterType: _selectedFilter,
      );

      final filteredMovies = newMovies
          .where((movie) => !containsFarsiOrArabic(movie.title))
          .toList();

      if (filteredMovies.isEmpty && newMovies.isNotEmpty) {
        _currentPage++;
        _isLoading = false;
        notifyListeners();
        await loadMovies();
        return;
      }

      if (newMovies.isEmpty) {
        _hasMore = false;
      } else {
        _movies.addAll(filteredMovies);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMovies() async {
    await loadMovies(refresh: true);
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    refreshMovies();
  }

  void selectFilter(FilterType filter) {
    _selectedFilter = filter;
    refreshMovies();
  }

  void resetFilters() {
    _selectedGenreId = 0;
    _selectedFilter = FilterType.defaultFilter;
    refreshMovies();
  }
}
