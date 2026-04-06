class OccupationModel {
  final String title;
  final String description;
  final String averageIncome;
  final String iconType;
  final List<String> pros;
  final List<String> cons;
  final String potentialKeywords;
  final String? externalUrl;
  final String? platformName;
  final bool isBestMatch;

  OccupationModel({
    required this.title,
    required this.description,
    required this.averageIncome,
    required this.iconType,
    required this.pros,
    required this.cons,
    required this.potentialKeywords,
    this.externalUrl,
    this.platformName,
    this.isBestMatch = false,
  });

  factory OccupationModel.fromJson(Map<String, dynamic> json) {
    return OccupationModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      averageIncome: json['averageIncome'] ?? '',
      iconType: json['iconType'] ?? '',
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
      potentialKeywords: json['potentialKeywords'] ?? '',
      externalUrl: json['externalUrl'],
      platformName: json['platformName'],
      isBestMatch: json['isBestMatch'] ?? false,
    );
  }
}
