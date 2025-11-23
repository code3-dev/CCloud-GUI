import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../repositories/seasons_repository.dart';

class SeasonsProvider with ChangeNotifier {
  final SeasonsRepository _seasonsRepository = SeasonsRepository();

  List<Season> _seasons = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _selectedSeasonIndex = 0;

  List<Season> get seasons {
    return _seasons;
  }

  bool get isLoading {
    return _isLoading;
  }

  String get errorMessage {
    print('Getting errorMessage: $_errorMessage');
    return _errorMessage;
  }

  int get selectedSeasonIndex {
    return _selectedSeasonIndex;
  }

  Season? get selectedSeason {
    final season = _seasons.isNotEmpty ? _seasons[_selectedSeasonIndex] : null;
    return season;
  }

  Future<void> loadSeasons(int seriesId) async {
    if (_isLoading) {
      return;
    }

    if (seriesId <= 0) {
      _errorMessage = 'شناسه سریال نامعتبر است';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _seasons = await _seasonsRepository.getSeasons(seriesId);
      _selectedSeasonIndex = 0;
    } catch (e) {
      print('Error loading seasons for series ID $seriesId: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSeason(int index) {
    if (index >= 0 && index < _seasons.length) {
      _selectedSeasonIndex = index;
      notifyListeners();
    } else {
      print('Invalid season index: $index, seasons length: ${_seasons.length}');
    }
  }
}
