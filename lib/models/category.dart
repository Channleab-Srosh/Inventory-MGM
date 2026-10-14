/// Category model
class Category {
  final String id;
  String name;
  String? color; // hex string e.g. '#FF5733'
  String? icon;
  DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Category copyWith({String? name, String? color, String? icon}) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
    );
  }
}
