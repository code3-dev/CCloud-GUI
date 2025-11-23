import 'dart:convert';
import '../models/media_item.dart';
import 'base_repository.dart';

class GenreRepository extends BaseRepository {
  static const String _genreEndpoint = '/genre/all';

  Future<List<Genre>> getGenres() async {
    try {
      final url = '$baseUrl$_genreEndpoint/$apiKey';
      final jsonData = await executeRequest(url);
      return parseGenres(jsonData);
    } catch (e) {
      throw Exception('Error fetching genres: $e');
    }
  }

  List<Genre> parseGenres(String jsonData) {
    final genres = <Genre>[];
    final jsonArray = json.decode(jsonData) as List;

    for (var item in jsonArray) {
      try {
        final genreObj = item as Map<String, dynamic>;
        final genre = Genre(
          id: genreObj['id'] as int? ?? 0,
          title: genreObj['title'] as String? ?? '',
        );
        genres.add(genre);
      } catch (e) {
        continue;
      }
    }

    genres.sort((a, b) => a.title.compareTo(b.title));
    return genres;
  }
}
