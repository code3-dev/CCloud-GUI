import 'dart:convert';
import '../models/media_item.dart';
import 'base_repository.dart';

class SeriesRepository extends BaseRepository {
  static const String _seriesEndpoint = '/serie/by/filtres';

  Future<List<MediaItem>> getSeries({
    int page = 0,
    int genreId = 0,
    FilterType filterType = FilterType.defaultFilter,
  }) async {
    try {
      final url =
          '$baseUrl$_seriesEndpoint/$genreId/${filterType.apiValue}/$page/$apiKey';
      final jsonData = await executeRequest(url);
      return parseSeries(jsonData);
    } catch (e) {
      throw Exception('Error fetching series: $e');
    }
  }

  List<MediaItem> parseSeries(String jsonData) {
    final seriesList = <MediaItem>[];
    final jsonArray = json.decode(jsonData) as List;

    for (var item in jsonArray) {
      try {
        final seriesObj = item as Map<String, dynamic>;
        final series = MediaItem(
          id: seriesObj['id'] as int? ?? 0,
          type: seriesObj['type'] as String? ?? '',
          title: seriesObj['title'] as String? ?? '',
          description: seriesObj['description'] as String? ?? '',
          year: seriesObj['year'] as int? ?? 0,
          imdb: (seriesObj['imdb'] as num?)?.toDouble() ?? 0.0,
          rating: (seriesObj['rating'] as num?)?.toDouble() ?? 0.0,
          duration: seriesObj['duration'] as String?,
          image: seriesObj['image'] as String? ?? '',
          cover: seriesObj['cover'] as String? ?? '',
          genres: parseGenres(seriesObj['genres'] as List? ?? []),
          sources: [], // Series don't have sources in this model
          countries: parseCountries(seriesObj['country'] as List? ?? []),
        );
        seriesList.add(series);
      } catch (e) {
        // Skip items that fail to parse
        continue;
      }
    }

    return seriesList;
  }

  List<Genre> parseGenres(List genresArray) {
    final genres = <Genre>[];
    for (var item in genresArray) {
      try {
        final genreObj = item as Map<String, dynamic>;
        genres.add(
          Genre(
            id: genreObj['id'] as int? ?? 0,
            title: genreObj['title'] as String? ?? '',
          ),
        );
      } catch (e) {
        // Skip genres that fail to parse
        continue;
      }
    }
    return genres;
  }

  List<Country> parseCountries(List countriesArray) {
    final countries = <Country>[];
    for (var item in countriesArray) {
      try {
        final countryObj = item as Map<String, dynamic>;
        countries.add(
          Country(
            id: countryObj['id'] as int? ?? 0,
            title: countryObj['title'] as String? ?? '',
            image: countryObj['image'] as String? ?? '',
          ),
        );
      } catch (e) {
        // Skip countries that fail to parse
        continue;
      }
    }
    return countries;
  }
}
