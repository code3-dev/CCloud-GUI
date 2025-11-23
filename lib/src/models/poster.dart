import 'media_item.dart';

class Poster {
  final int id;
  final String title;
  final String type;
  final String description;
  final int year;
  final double imdb;
  final double rating;
  final String? duration;
  final String? image;
  final String cover;
  final List<Genre> genres;
  final List<Source> sources;
  final List<Country> countries;

  Poster({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.year,
    required this.imdb,
    required this.rating,
    this.duration,
    this.image,
    required this.cover,
    required this.genres,
    required this.sources,
    required this.countries,
  });

  factory Poster.fromJson(Map<String, dynamic> json) {
    return Poster(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      imdb: (json['imdb'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String?,
      image: json['image'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      genres:
          (json['genres'] as List?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sources:
          (json['sources'] as List?)
              ?.map((e) => Source.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      countries:
          (json['country'] as List?)
              ?.map((e) => Country.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'year': year,
      'imdb': imdb,
      'rating': rating,
      'duration': duration,
      'image': image,
      'cover': cover,
      'genres': genres.map((e) => e.toJson()).toList(),
      'sources': sources.map((e) => e.toJson()).toList(),
      'country': countries.map((e) => e.toJson()).toList(),
    };
  }

  bool isMovie() => type == 'movie';
  bool isSeries() => type == 'serie';

  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      type: type,
      title: title,
      description: description,
      year: year,
      imdb: imdb,
      rating: rating,
      duration: duration,
      image: image ?? '',
      cover: cover,
      genres: genres,
      sources: sources,
      countries: countries,
    );
  }
}
