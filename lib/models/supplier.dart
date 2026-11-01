/// Supplier model
class Supplier {
  final String id;
  String name;
  String? phone;
  String? email;
  String? address;
  String? contactPerson;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.contactPerson,
    this.status = 'Active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      contactPerson: json['contactPerson']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'contactPerson': contactPerson,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status.toLowerCase() == 'active';

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
    String? status,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
