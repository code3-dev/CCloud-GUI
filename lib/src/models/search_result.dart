import 'poster.dart';

class SearchResult {
  final List<Poster> posters;

  SearchResult({required this.posters});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      posters: (json['posters'] as List)
          .map((e) => Poster.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'posters': posters.map((e) => e.toJson()).toList()};
  }
}
