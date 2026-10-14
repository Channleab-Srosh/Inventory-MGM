/// Supplier model
class Supplier {
  final String id;
  String name;
  String? phone;
  String? email;
  String? address;
  String? contactPerson;
  DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Avatar initials from name
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Supplier copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? contactPerson,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      createdAt: createdAt,
    );
  }
}
