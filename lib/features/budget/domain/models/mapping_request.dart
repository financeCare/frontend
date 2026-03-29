class MappingRequest {
  final String receiverName;
  final int categoryId;

  MappingRequest({
    required this.receiverName,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'categoryId': categoryId,
    };
  }
}
