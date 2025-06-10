import 'dart:convert';

import 'package:collabocate/src/config/config.dart';
import 'package:collabocate/src/models/template_model.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  final String baseUrl = AppConfig.backendUrl;

  Future<List<IssueTemplate>> fetchIssueTemplates() async {
    final url = Uri.parse(
      '$baseUrl/external/github/templates/issues',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is! Map) {
          throw Exception(
            'Invalid API response format.',
          );
        }

        if (decodedResponse['success'] == true &&
            decodedResponse.containsKey('data')) {
          if (decodedResponse['data'] is List) {
            return (decodedResponse['data'] as List)
                .map(
                  (template) => IssueTemplate.fromJson(template),
                )
                .toList();
          }
        }
      }
      print('Failed to load templates: ${response.statusCode}');
      throw Exception(
        'Failed to load templates: ${response.statusCode}',
      );
    } catch (e) {
      print('Error fetching templates: $e');
      throw Exception(
        'Error fetching templates: $e',
      );
    }
  }

  Future<void> createIssue(String title, String body) async {
    final url = Uri.parse(
      '$baseUrl/external/github/issues',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
        }),
      );
      if (response.statusCode != 201) {
        throw Exception(
          'Failed to create issue: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
