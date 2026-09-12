class VocabularyLibrary {
  const VocabularyLibrary({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon = 'book',
    this.colorValue = 0xFF4F46E5,
    this.isSystemLibrary = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String icon;
  final int colorValue;
  final bool isSystemLibrary;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  VocabularyLibrary copyWith({
    String? name,
    String? description,
    String? icon,
    int? colorValue,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return VocabularyLibrary(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isSystemLibrary: isSystemLibrary,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'icon': icon,
        'color_value': colorValue,
        'is_system_library': isSystemLibrary ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VocabularyLibrary.fromMap(Map<String, Object?> map) {
    return VocabularyLibrary(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      name: map['name']! as String,
      description: map['description'] as String?,
      icon: (map['icon'] as String?) ?? 'book',
      colorValue: (map['color_value'] as int?) ?? 0xFF4F46E5,
      isSystemLibrary: (map['is_system_library'] as int? ?? 0) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: _date(map['deleted_at']),
      createdAt: _date(map['created_at']) ?? DateTime.now(),
      updatedAt: _date(map['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
