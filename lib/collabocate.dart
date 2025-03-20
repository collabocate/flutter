library collabocate_ui_plugin;

import 'package:collabocate/src/config/config.dart';
import 'package:collabocate/src/models/template_model.dart';
import 'package:collabocate/src/services/github_service.dart';
import 'package:collabocate/src/ui/issue_form.dart';
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
  String? selectedTemplateType;
  bool isLoading = false;
  bool isInitialized = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    try {
      await AppConfig.initialize();
      setState(() {
        _service = GitHubService();
        isInitialized = true;
      });
      await _fetchTemplates();
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
        heroTag: 'uniqueSpeedDialTag',
        animatedIcon: AnimatedIcons.add_event,
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
                    onIssueCreated: _fetchTemplates,
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
            onTap: () {},
            child: Icon(
              Icons.notifications_outlined,
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
