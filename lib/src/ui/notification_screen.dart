import 'package:collabocate/src/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatelessWidget {
  final List<GithubNotification> notifications;
  final VoidCallback onRefresh;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  const NotificationScreen({
    super.key,
    required this.notifications,
    required this.onRefresh,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Notifications',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: onRefresh,
          ),
          if (notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(
                Icons.done_all,
              ),
              onPressed: onMarkAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications',
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  // Sort notifications by date (newest first)
                  final sortedNotifications =
                      List<GithubNotification>.from(notifications)
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final notification = sortedNotifications[index];

                  return NotificationTile(
                    notification: notification,
                    onMarkAsRead: onMarkAsRead,
                  );
                },
              ),
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final GithubNotification notification;
  final Function(String) onMarkAsRead;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
  });

  void _openIssue() async {
    final url = Uri.parse(notification.issueUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      onMarkAsRead(notification.id);
    } else {
      print("Could not launch URL: ${notification.issueUrl}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(
      'MMM d, yyyy . h:mm a',
    );

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      onDismissed: (_) => onMarkAsRead(
        notification.id,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
          child: const Icon(
            Icons.notification_important,
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              dateFormat.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: _openIssue,
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => onMarkAsRead(notification.id),
                tooltip: 'Mark as read',
              ),
      ),
    );
  }
}
