library collabocate_ui_plugin;

import 'dart:async';

import 'package:collabocate/src/config/config.dart';
import 'package:collabocate/src/models/template_model.dart';
import 'package:collabocate/src/services/github_service.dart';
import 'package:collabocate/src/services/notification_manager.dart';
import 'package:collabocate/src/ui/issue_form.dart';
import 'package:collabocate/src/ui/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class Collabocate extends StatefulWidget {
  const Collabocate({super.key});

  @override
  State<Collabocate> createState() => _CollabocateState();
}

class _CollabocateState extends State<Collabocate> {
  //late final GitHubService _service = GitHubService();
  GitHubService? _service;
  List<IssueTemplate> templates = [];
  List<GithubNotification> notifications = [];
  String? selectedTemplateType;
  bool isLoading = false;
  bool isInitialized = false;
  String? errorMessage;
  bool hasNewNotifications = false;
  int notificationCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeConfig() async {
    try {
      await AppConfig.initialize();
      setState(() {
        _service = GitHubService();
        isInitialized = true;
      });
      await _fetchTemplates();
      await _fetchNotifications();

      // Set up a timer to periodically check for new notifications
      _notificationTimer = Timer.periodic(
        const Duration(seconds: 30), // Check every 30 seconds
        (_) => _fetchNotifications(),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchTemplates() async {
    if (_service == null) return;

    setState(
      () => isLoading = true,
    );
    try {
      templates = await _service!.fetchIssueTemplates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load templates: $e'),
        ),
      );
    } finally {
      setState(
        () => isLoading = false,
      );
    }
  }

  Future<void> _fetchNotifications() async {
    if (_service == null) return;

    try {
      final fetchedNotifications = await _service!.fetchNotifications();
      final unreadCount = await _service!.getUnreadCount();

      setState(() {
        notifications = fetchedNotifications;
        notificationCount = unreadCount;
        hasNewNotifications = unreadCount > 0;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error fetching notifications: $e');
    }
  }

  void _clearNotifications() async {
    if (_service == null) return;

    try {
      await _service!.markAllNotificationsAsRead();
      await _fetchNotifications(); // Refresh notifications after marking all as read
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark notifications as read: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Configuration Error: $errorMessage\nPlease ensure .env file exists with BACKEND_URL.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      floatingActionButton: SpeedDial(
        elevation: 0,
        icon: Icons.add,
        activeIcon: Icons.close,
        heroTag: 'uniqueSpeedDialTag',
        spacing: 8,
        spaceBetweenChildren: 8,
        overlayColor: Colors.black,
        overlayOpacity: 0.2,
        children: [
          SpeedDialChild(
            elevation: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueForm(
                    templates: templates,
                    service: _service,
                    onIssueCreated: () async {
                      await _fetchTemplates();
                      await _fetchNotifications();
                    },
                  ),
                ),
              );
            },
            child: Icon(
              Icons.report_problem_outlined,
            ),
            label: 'Report Issue',
            labelStyle: TextStyle(
              fontSize: 18,
            ),
          ),
          SpeedDialChild(
            elevation: 0,
            onTap: () {
              _clearNotifications();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                    notifications: notifications,
                    onRefresh: _fetchNotifications,
                    onMarkAsRead: (String notificationId) async {
                      await _service?.markNotificationAsRead(notificationId);
                      await _fetchNotifications();
                    },
                    onMarkAllAsRead: _clearNotifications,
                  ),
                ),
              ).then(
                (_) => _fetchNotifications(),
              );
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  Icons.notifications_outlined,
                ),
                if (hasNewNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: notificationCount > 0
                          ? Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 5,
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
            label: 'Notification',
            labelStyle: TextStyle(
              fontSize: 18,
            ),
          ),
          SpeedDialChild(
            elevation: 0,
            onTap: () {},
            child: Icon(
              Icons.chat_outlined,
            ),
            label: 'Chats',
            labelStyle: TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
