/// Category model
class Category {
  final String id;
  String name;
  String? description;
  String? color; // hex string e.g. '#FF5733'
  String? icon;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Category.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final defaultStyle = _guessStyle(name);

    return Category(
      id: json['id']?.toString() ?? '',
      name: name,
      description: json['description']?.toString(),
      color: json['color']?.toString() ?? defaultStyle.$1,
      icon: json['icon']?.toString() ?? defaultStyle.$2,
      isActive: json['active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static (String, String) _guessStyle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('drink') || lower.contains('bever')) return ('#06B6D4', 'local_drink');
    if (lower.contains('food') || lower.contains('grocer') || lower.contains('snack')) return ('#10B981', 'restaurant');
    if (lower.contains('elect') || lower.contains('tech') || lower.contains('gadget')) return ('#3B82F6', 'devices');
    if (lower.contains('office') || lower.contains('suppl')) return ('#8B5CF6', 'work');
    if (lower.contains('stat') || lower.contains('pen') || lower.contains('paper')) return ('#EC4899', 'edit');
    if (lower.contains('furn') || lower.contains('desk') || lower.contains('chair')) return ('#F59E0B', 'chair');
    if (lower.contains('cloth') || lower.contains('wear') || lower.contains('apparel')) return ('#EF4444', 'checkroom');
    if (lower.contains('tool') || lower.contains('hardw')) return ('#6B7280', 'build');
    return ('#6366F1', 'category');
  }

  Category copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
