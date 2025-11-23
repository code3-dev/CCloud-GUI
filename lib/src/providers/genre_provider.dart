import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/genre_repository.dart';

class GenreProvider with ChangeNotifier {
  final GenreRepository _genreRepository = GenreRepository();

  List<Genre> _genres = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _selectedGenreId = 0;

  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get selectedGenreId => _selectedGenreId;
  Genre? get selectedGenre =>
      _genres.firstWhereOrNull((genre) => genre.id == _selectedGenreId);

  Future<void> loadGenres() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _genres = await _genreRepository.getGenres();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectGenre(int genreId) {
    _selectedGenreId = genreId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedGenreId = 0;
    notifyListeners();
  }
}

extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
