import 'dart:convert';

import 'package:collabocate/src/config/config.dart';
import 'package:collabocate/src/models/template_model.dart';
import 'package:collabocate/src/services/notification_manager.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  final String baseUrl = AppConfig.backendUrl;
  final NotificationManager _notificationManager = NotificationManager();

  Future<List<IssueTemplate>> fetchIssueTemplates() async {
    final url = Uri.parse(
      '$baseUrl/external/github/templates/issues',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is! Map ||
            !decodedResponse.containsKey('templates')) {
          throw Exception(
            'Invalid API response format.',
          );
        }

        if (decodedResponse['templates'] is List) {
          return (decodedResponse['templates'] as List)
              .map(
                (template) => IssueTemplate.fromJson(template),
              )
              .toList();
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

      // Create local notification for the new issue
      await _notificationManager.addNotification(
        title: title,
        body: body.length > 100 ? '${body.substring(0, 100)}...' : body,
        type: 'issue_created',
        // Use a placeholder URL until backend provides an actual URL
        issueUrl:
            'https://github.com/collabo-community/use-me-for-experiments/issues',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to fetch notifications from local storage
  Future<List<GithubNotification>> fetchNotifications() async {
    return await _notificationManager.getNotifications();
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationManager.markAsRead(notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    await _notificationManager.markAllAsRead();
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    return await _notificationManager.getUnreadCount();
  }
}
