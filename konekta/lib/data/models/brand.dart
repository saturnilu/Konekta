class Brand {
  final int id;
  final int userId;
  final String name;
  final String? industry;
  final String? location;
  final String? logoUrl;
  final String? description;

  Brand({
    required this.id,
    required this.userId,
    required this.name,
    this.industry,
    this.location,
    this.logoUrl,
    this.description,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: (json['id'] ?? 0) as int,
      userId: (json['user_id'] ?? json['id'] ?? 0) as int,
      name: (json['name'] ?? json['brand_name'] ?? '') as String,
      industry: json['industry'] as String?,
      location: json['location'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
    );
  }
}
