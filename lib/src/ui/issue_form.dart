import 'package:collabocate/src/models/template_model.dart';
import 'package:collabocate/src/services/github_service.dart';
import 'package:flutter/material.dart';

class IssueForm extends StatefulWidget {
  final List<IssueTemplate> templates;
  final GitHubService? service;
  final VoidCallback? onIssueCreated;

  const IssueForm({
    super.key,
    required this.templates,
    this.service,
    this.onIssueCreated,
  });

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  String? selectedTemplateType;
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  bool isLoading = false;

  Future<void> _updateIssueBody(String? templateType) async {
    if (widget.service == null || templateType == null) return;

    setState(() => isLoading = true);
    try {
      final template = widget.templates.firstWhere(
        (template) => template.title == templateType,
        orElse: () => IssueTemplate(
          title: '',
          content: '',
        ),
      );

      setState(() {
        selectedTemplateType = templateType;
        bodyController.text = template.content;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load template: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(
        () => isLoading = false,
      );
    }
  }

  Future<void> _createIssue() async {
    if (widget.service == null) return;

    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide both title and body for the issue.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(
      () => isLoading = true,
    );
    try {
      await widget.service!.createIssue(title, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onIssueCreated != null) {
        widget.onIssueCreated!();
      }

      titleController.clear();
      bodyController.clear();
      setState(
        () {
          selectedTemplateType = null;
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Issue',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose report type',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedTemplateType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                labelText: 'Template Type',
              ),
              items: widget.templates.map((template) {
                return DropdownMenuItem(
                  value: template.title,
                  child: Text(
                    template.title,
                  ),
                );
              }).toList(),
              onChanged: (value) => _updateIssueBody(value),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                labelText: 'Issue Title',
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: bodyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                labelText: 'Issue Body',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : _createIssue,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Issue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
