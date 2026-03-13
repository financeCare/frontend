class JobModel {
  final String id;
  final String title;
  final String type; // e.g., 'Freelance', 'Part-time', 'Delivery'
  final String estimatedIncome;
  final String description;
  final String requirement;
  final String applyUrl;
  final bool isRecommended;

  JobModel({
    required this.id,
    required this.title,
    required this.type,
    required this.estimatedIncome,
    required this.description,
    required this.requirement,
    required this.applyUrl,
    this.isRecommended = false,
  });
}
