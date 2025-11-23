class MediaItem {
  final int id;
  final String type;
  final String title;
  final String description;
  final int year;
  final double imdb;
  final double rating;
  final String? duration;
  final String image;
  final String cover;
  final List<Genre> genres;
  final List<Source> sources;
  final List<Country> countries;

  MediaItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.year,
    required this.imdb,
    required this.rating,
    this.duration,
    required this.image,
    required this.cover,
    required this.genres,
    required this.sources,
    required this.countries,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
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
      'type': type,
      'title': title,
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
}

class Genre {
  final int id;
  final String title;

  Genre({required this.id, required this.title});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] as int, title: json['title'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }
}

class Source {
  final int id;
  final String quality;
  final String type;
  final String url;

  Source({
    required this.id,
    required this.quality,
    required this.type,
    required this.url,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] as int,
      quality: json['quality'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'quality': quality, 'type': type, 'url': url};
  }
}

class Country {
  final int id;
  final String title;
  final String image;

  Country({required this.id, required this.title, required this.image});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'image': image};
  }
}

class Season {
  final int id;
  final String title;
  final List<Episode> episodes;

  Season({required this.id, required this.title, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      episodes:
          (json['episodes'] as List?)
              ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  final int id;
  final String title;
  final String description;
  final String? duration;
  final String image;
  final List<Source> sources;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    this.duration,
    required this.image,
    required this.sources,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String?,
      image: json['image'] as String? ?? '',
      sources: (json['sources'] as List)
          .map((e) => Source.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'image': image,
      'sources': sources.map((e) => e.toJson()).toList(),
    };
  }
}

enum FilterType {
  defaultFilter,
  byYear,
  byImdb;

  String get apiValue {
    switch (this) {
      case FilterType.defaultFilter:
        return 'created';
      case FilterType.byYear:
        return 'year';
      case FilterType.byImdb:
        return 'imdb';
    }
  }
}
