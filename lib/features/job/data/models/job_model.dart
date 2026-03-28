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
  }) : assert(title.isNotEmpty, 'Job title cannot be empty'),
       assert(estimatedIncome.isNotEmpty, 'Estimated income must be provided'),
       assert(platformLinks.isNotEmpty, 'At least one platform link must be provided');
}
