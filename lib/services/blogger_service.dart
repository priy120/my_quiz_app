import 'package:http/http.dart' as http;
import 'dart:convert';

class BloggerService {
  static const String apiKey = 'AIzaSyA16nNuPLA5C8DUjJCIbJqTSWXcTtKqalc';
  static const String blogId = '6285578520340531355';

  static Future<List<dynamic>> fetchLatestTests() async {
    final url = Uri.parse(
      'https://www.googleapis.com/blogger/v3/blogs/$blogId/posts?key=$apiKey',
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}