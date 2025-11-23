import 'dart:convert';
import '../models/media_item.dart';
import 'base_repository.dart';

class SeasonsRepository extends BaseRepository {
  static const String _seasonsEndpoint = '/season/by/serie';

  Future<List<Season>> getSeasons(int seriesId) async {
    if (seriesId <= 0) {
      print('Invalid seriesId: $seriesId');
      throw Exception('Invalid series ID');
    }

    try {
      final url = '$baseUrl$_seasonsEndpoint/$seriesId/$apiKey/';
      final jsonData = await executeRequest(url);
      final result = parseSeasons(jsonData);
      return result;
    } catch (e) {
      print('Error in SeasonsRepository.getSeasons: $e');
      throw Exception('Error fetching seasons: $e');
    }
  }

  List<Season> parseSeasons(String jsonData) {
    final seasons = <Season>[];
    final jsonArray = json.decode(jsonData) as List;
    for (var item in jsonArray) {
      try {
        final seasonObj = item as Map<String, dynamic>;
        final season = parseSeason(seasonObj);
        seasons.add(season);
      } catch (e) {
        print('Error parsing season: $e');
        continue;
      }
    }

    return seasons;
  }

  Season parseSeason(Map<String, dynamic> seasonObj) {
    final id = seasonObj['id'] as int? ?? 0;
    final title = seasonObj['title'] as String? ?? '';
    return Season(
      id: id,
      title: title,
      episodes: parseEpisodes(seasonObj['episodes'] as List? ?? []),
    );
  }

  List<Episode> parseEpisodes(List episodesArray) {
    final episodes = <Episode>[];
    for (var item in episodesArray) {
      try {
        final episodeObj = item as Map<String, dynamic>;
        final id = episodeObj['id'] as int? ?? 0;
        final title = episodeObj['title'] as String? ?? '';
        episodes.add(
          Episode(
            id: id,
            title: title,
            description: episodeObj['description'] as String? ?? '',
            duration: episodeObj['duration'] as String? ?? '',
            image: episodeObj['image'] as String? ?? '',
            sources: parseSources(episodeObj['sources'] as List? ?? []),
          ),
        );
      } catch (e) {
        print('Error parsing episode: $e');
        continue;
      }
    }
    return episodes;
  }

  List<Source> parseSources(List sourcesArray) {
    final sources = <Source>[];
    for (var item in sourcesArray) {
      try {
        final sourceObj = item as Map<String, dynamic>;
        final id = sourceObj['id'] as int? ?? 0;
        final quality = sourceObj['quality'] as String? ?? '';
        final type = sourceObj['type'] as String? ?? '';
        final url = sourceObj['url'] as String? ?? '';
        sources.add(Source(id: id, quality: quality, type: type, url: url));
      } catch (e) {
        print('Error parsing source: $e');
        // Skip sources that fail to parse
        continue;
      }
    }
    return sources;
  }
}
