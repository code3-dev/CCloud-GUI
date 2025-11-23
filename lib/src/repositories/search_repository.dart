import 'dart:convert';
import '../models/poster.dart';
import '../models/search_result.dart';
import '../models/media_item.dart';
import 'base_repository.dart';

class SearchRepository extends BaseRepository {
  static const String _searchEndpoint = '/search';

  Future<SearchResult> search(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl$_searchEndpoint/$encodedQuery/$apiKey/';
      final jsonData = await executeRequest(url);
      return parseSearchResult(jsonData);
    } catch (e) {
      print('Error in SearchRepository.search: $e');
      throw Exception('Error searching: $e');
    }
  }

  SearchResult parseSearchResult(String jsonData) {
    final jsonObject = json.decode(jsonData) as Map<String, dynamic>;
    final postersArray = jsonObject['posters'] as List;
    final posters = parsePosters(postersArray);

    return SearchResult(posters: posters);
  }

  List<Poster> parsePosters(List postersArray) {
    final posters = <Poster>[];
    for (var item in postersArray) {
      try {
        final posterObj = item as Map<String, dynamic>;
        posters.add(parsePoster(posterObj));
      } catch (e) {
        print('Error parsing poster: $e');
        continue;
      }
    }
    return posters;
  }

  Poster parsePoster(Map<String, dynamic> posterObj) {
    final id = posterObj['id'] as int? ?? 0;
    final type = posterObj['type'] as String? ?? '';
    final title = posterObj['title'] as String? ?? '';

    return Poster(
      id: id,
      title: title,
      type: type,
      description: posterObj['description'] as String? ?? '',
      year: posterObj['year'] as int? ?? 0,
      imdb: (posterObj['imdb'] as num?)?.toDouble() ?? 0.0,
      rating: (posterObj['rating'] as num?)?.toDouble() ?? 0.0,
      duration: posterObj['duration'] as String?,
      image: posterObj['image'] as String? ?? '',
      cover: posterObj['cover'] as String? ?? '',
      genres: parseGenres(posterObj['genres'] as List? ?? []),
      sources: parseSources(posterObj['sources'] as List? ?? []),
      countries: parseCountries(posterObj['country'] as List? ?? []),
    );
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
        print('Error parsing genre: $e');
        continue;
      }
    }
    return genres;
  }

  List<Source> parseSources(List sourcesArray) {
    final sources = <Source>[];
    for (var item in sourcesArray) {
      try {
        final sourceObj = item as Map<String, dynamic>;
        sources.add(
          Source(
            id: sourceObj['id'] as int? ?? 0,
            quality: sourceObj['quality'] as String? ?? '',
            type: sourceObj['type'] as String? ?? '',
            url: sourceObj['url'] as String? ?? '',
          ),
        );
      } catch (e) {
        print('Error parsing source: $e');
        continue;
      }
    }
    return sources;
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
        print('Error parsing country: $e');
        // Skip countries that fail to parse
        continue;
      }
    }
    return countries;
  }
}
