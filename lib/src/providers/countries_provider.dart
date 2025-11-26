import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/poster.dart';
import '../models/media_item.dart';
import '../repositories/countries_repository.dart';

class CountriesProvider with ChangeNotifier {
  final CountriesRepository _repository = CountriesRepository();
  
  List<CountryModel> _countries = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<CountryModel> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadCountries() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _countries = await _repository.getCountries();
    } catch (e) {
      _errorMessage = e.toString();
      _countries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class CountryMediaProvider with ChangeNotifier {
  final CountriesRepository _repository = CountriesRepository();
  
  List<Poster> _mediaItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  FilterType _currentFilter = FilterType.defaultFilter;
  
  List<Poster> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FilterType get currentFilter => _currentFilter;
  
  Future<void> loadMediaByCountry(int countryId, {FilterType? filterType}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    _mediaItems = [];
    if (filterType != null) {
      _currentFilter = filterType;
    }
    notifyListeners();
    
    try {
      _mediaItems = await _repository.getPostersByCountry(countryId, filterType: _currentFilter);
    } catch (e) {
      _errorMessage = e.toString();
      _mediaItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}