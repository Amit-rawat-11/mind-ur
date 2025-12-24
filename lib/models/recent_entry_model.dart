
class RecentEntryModel {
  final String title;
  final String category;
  final String lastUpdated;

  RecentEntryModel({
    required this.title,
    required this.category,
    required this.lastUpdated,
  });

  factory RecentEntryModel.fromJson(Map<String, dynamic> json) {
    return RecentEntryModel(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'lastUpdated': lastUpdated,
    };
  }
}
