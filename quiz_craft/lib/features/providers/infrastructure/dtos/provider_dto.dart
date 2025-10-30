import '../../domain/entities/provider_entity.dart';

class ProviderDto {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> specialties;
  final double rating;
  final bool isActive;
  final DateTime createdAt;

  ProviderDto({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.specialties = const [],
    this.rating = 0.0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();


  factory ProviderDto.fromMap(Map<String, dynamic> map) {
    return ProviderDto(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      specialties: map['specialties'] != null
          ? List<String>.from(map['specialties'] as List)
          : <String>[],
      rating: map['rating'] != null
          ? (map['rating'] is num ? (map['rating'] as num).toDouble() : double.tryParse(map['rating'].toString()) ?? 0.0)
          : 0.0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
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

  ProviderEntity toEntity() {
    return ProviderEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      specialties: specialties,
      rating: rating,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  factory ProviderDto.fromEntity(ProviderEntity entity) {
    return ProviderDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      specialties: entity.specialties,
      rating: entity.rating,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
