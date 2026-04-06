class JobModel {
  final String id;
  final String title;
  final String type; // e.g., 'Freelance', 'Part-time', 'Delivery'
  final String estimatedIncome;
  final String description;
  final String requirement;
  final Map<String, String> platformLinks; // e.g., {'JobsDB': 'url', 'Fastwork': 'url'}
  final bool isRecommended;

  JobModel({
    required this.id,
    required this.title,
    required this.type,
    required this.estimatedIncome,
    required this.description,
    required this.requirement,
    required this.platformLinks,
    this.isRecommended = false,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      estimatedIncome: json['estimatedIncome'] ?? '',
      description: json['description'] ?? '',
      requirement: json['requirement'] ?? '',
      platformLinks: Map<String, String>.from(json['platformLinks'] ?? {}),
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}
