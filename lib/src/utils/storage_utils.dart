import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

// Wrapper class to add timestamp to MediaItem for favorites
class MediaItemWithTimestamp {
  final MediaItem mediaItem;
  final int timestamp;
  
  MediaItemWithTimestamp(this.mediaItem, this.timestamp);
  
  Map<String, dynamic> toJson() {
    final json = mediaItem.toJson();
    json['timestamp'] = timestamp;
    return json;
  }
  
  static MediaItemWithTimestamp fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    // Remove timestamp before creating MediaItem
    final jsonWithoutTimestamp = Map<String, dynamic>.from(json);
    jsonWithoutTimestamp.remove('timestamp');
    final mediaItem = MediaItem.fromJson(jsonWithoutTimestamp);
    return MediaItemWithTimestamp(mediaItem, timestamp);
  }
}

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

  static Future<File> get _localFavoritesFile async {
    final path = await _localPath;
    return File('$path/favorites.json');
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

  // Add a media item to favorites with timestamp
  static Future<void> addToFavorites(MediaItem mediaItem) async {
    try {
      final favorites = await loadFavoritesWithTimestamp();
      // Check if item already exists
      final existingIndex = favorites.indexWhere((item) => item.mediaItem.id == mediaItem.id && item.mediaItem.type == mediaItem.type);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      if (existingIndex != -1) {
        // Update existing item's timestamp
        favorites.removeAt(existingIndex);
        favorites.insert(0, MediaItemWithTimestamp(mediaItem, timestamp));
      } else {
        // Add new item at the beginning (newest first)
        favorites.insert(0, MediaItemWithTimestamp(mediaItem, timestamp));
      }
      await _saveFavoritesWithTimestamp(favorites);
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  // Remove a media item from favorites
  static Future<void> removeFromFavorites(int id, String type) async {
    try {
      final favorites = await loadFavoritesWithTimestamp();
      favorites.removeWhere((item) => item.mediaItem.id == id && item.mediaItem.type == type);
      await _saveFavoritesWithTimestamp(favorites);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  // Load all favorites with timestamps
  static Future<List<MediaItemWithTimestamp>> loadFavoritesWithTimestamp() async {
    try {
      final file = await _localFavoritesFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonArray = jsonDecode(jsonString) as List<dynamic>;
        final favorites = <MediaItemWithTimestamp>[];
        
        for (final item in jsonArray) {
          final jsonMap = item as Map<String, dynamic>;
          final favoriteItem = MediaItemWithTimestamp.fromJson(jsonMap);
          favorites.add(favoriteItem);
        }
        
        // Sort by timestamp descending (newest first)
        favorites.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return favorites;
      }
      return [];
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  // Load all favorites (backward compatibility)
  static Future<List<MediaItem>> loadFavorites() async {
    final favoritesWithTimestamp = await loadFavoritesWithTimestamp();
    return favoritesWithTimestamp.map((item) => item.mediaItem).toList();
  }

  // Clear all favorites
  static Future<void> clearAllFavorites() async {
    try {
      final file = await _localFavoritesFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  // Save favorites to file with timestamps
  static Future<void> _saveFavoritesWithTimestamp(List<MediaItemWithTimestamp> favorites) async {
    try {
      final file = await _localFavoritesFile;
      final jsonArray = favorites.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonArray);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Check if a media item is in favorites
  static Future<bool> isFavorite(int id, String type) async {
    try {
      final favorites = await loadFavorites();
      return favorites.any((item) => item.id == id && item.type == type);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }
}

bool containsFarsiOrArabic(String text) {
  final farsiArabicRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  return farsiArabicRegex.hasMatch(text);
}