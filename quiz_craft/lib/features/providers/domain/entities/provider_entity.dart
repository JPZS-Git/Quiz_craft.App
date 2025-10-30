class ProviderEntity {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> specialties;
  final double rating;
  final bool isActive;
  final DateTime createdAt;

  ProviderEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.specialties = const [],
    this.rating = 0.0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ProviderEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? specialties,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProviderEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProviderEntity.fromJson(Map<String, dynamic> json) {
    return ProviderEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : <String>[],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialties': specialties,
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ProviderEntity(id: $id, name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProviderEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.rating == rating &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        (email?.hashCode ?? 0) ^
        (phone?.hashCode ?? 0) ^
        rating.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode;
  }
}
