import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

class StorageUtils {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localMoviesFile async {
    final path = await _localPath;
    return File('$path/movies.json');
  }

  static Future<File> get _localSeriesFile async {
    final path = await _localPath;
    return File('$path/series.json');
  }

  // Save a single movie to storage
  static Future<void> saveMovie(MediaItem movie) async {
    try {
      // Clear all existing movie data first
      await clearAllMovies();

      final file = await _localMoviesFile;
      final jsonString = jsonEncode(movie.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      // Handle error silently or log it
      print('Error saving movie: $e');
    }
  }

  // Load a movie from storage
  static Future<MediaItem?> loadMovie() async {
    try {
      final file = await _localMoviesFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return MediaItem.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      // Handle error silently or log it
      print('Error loading movie: $e');
      return null;
    }
  }

  // Clear all movies from storage
  static Future<void> clearAllMovies() async {
    try {
      final file = await _localMoviesFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Handle error silently or log it
      print('Error clearing movies: $e');
    }
  }

  // Save a single series to storage
  static Future<void> saveSeries(MediaItem series) async {
    try {
      // Clear all existing series data first
      await clearAllSeries();

      final file = await _localSeriesFile;
      final jsonString = jsonEncode(series.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      // Handle error silently or log it
      print('Error saving series: $e');
    }
  }

  // Load a series from storage
  static Future<MediaItem?> loadSeries() async {
    try {
      final file = await _localSeriesFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return MediaItem.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      // Handle error silently or log it
      print('Error loading series: $e');
      return null;
    }
  }

  // Clear all series from storage
  static Future<void> clearAllSeries() async {
    try {
      final file = await _localSeriesFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Handle error silently or log it
      print('Error clearing series: $e');
    }
  }
}

bool containsFarsiOrArabic(String text) {
  final farsiArabicRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  return farsiArabicRegex.hasMatch(text);
}
