import 'package:http/http.dart' as http;

class BaseRepository {
  static const String _apiKey = '4F5A9C3D9A86FA54EACEDDD635185';
  static const String _baseUrl = 'https://server-hi-speed-iran.info/api';

  static const List<String> _helperServers = [
    'https://hostinnegar.com',
    'https://windowsdiba.info',
  ];

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  List<String> get helperServers => _helperServers;

  Future<String> executeRequest(String primaryUrl) async {
    try {
      final response = await http.get(Uri.parse(primaryUrl));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Primary server returned error: ${response.statusCode}',
        );
      }
    } catch (primaryException) {
      for (String helperServer in _helperServers) {
        try {
          final helperUrl = primaryUrl.replaceFirst(
            RegExp(r'^https?://[^/]+'),
            helperServer,
          );
          final response = await http.get(Uri.parse(helperUrl));
          if (response.statusCode == 200) {
            return response.body;
          }
        } catch (helperException) {
          continue;
        }
      }
      rethrow;
    }
  }
}
