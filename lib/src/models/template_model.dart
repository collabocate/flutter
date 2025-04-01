class IssueTemplate {
  final String title;
  final String content;

  IssueTemplate({
    required this.title,
    required this.content,
  });
  factory IssueTemplate.fromJson(Map<String, dynamic> json) {
    return IssueTemplate(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
