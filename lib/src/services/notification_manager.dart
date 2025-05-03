import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GithubNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String issueUrl;

  GithubNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    required this.issueUrl,
  });

  factory GithubNotification.fromJson(Map<String, dynamic> json) {
    return GithubNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      issueUrl: json['issue_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'issue_url': issueUrl,
    };
  }
}

class NotificationManager {
  static const String _storageKey = 'github_notifications';
  final Uuid _uuid = const Uuid();

  // Get all notifications
  Future<List<GithubNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_storageKey);

    if (notificationsJson == null) {
      return [];
    }

    final List<dynamic> decodedList = json.decode(notificationsJson);
    return decodedList
        .map((item) => GithubNotification.fromJson(item))
        .toList();
  }

  // Save notifications
  Future<void> _saveNotifications(
      List<GithubNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = notifications
        .map(
          (notification) => notification.toJson(),
        )
        .toList();
    await prefs.setString(
      _storageKey,
      json.encode(jsonList),
    );
  }

  // Add a new notification
  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'issue',
    required String issueUrl,
  }) async {
    final notifications = await getNotifications();

    final newNotification = GithubNotification(
      id: _uuid.v4(),
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      issueUrl: issueUrl,
    );

    notifications.add(newNotification);
    await _saveNotifications(notifications);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();

    final updatedNotifications = notifications.map((notification) {
      if (notification.id == notificationId) {
        return GithubNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          createdAt: notification.createdAt,
          isRead: true,
          issueUrl: notification.issueUrl,
        );
      }
      return notification;
    }).toList();

    await _saveNotifications(updatedNotifications);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();

    final updatedNotifications = notifications.map((notification) {
      return GithubNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        createdAt: notification.createdAt,
        isRead: true,
        issueUrl: notification.issueUrl,
      );
    }).toList();

    await _saveNotifications(updatedNotifications);
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications
        .where(
          (notification) => !notification.isRead,
        )
        .length;
  }
}
