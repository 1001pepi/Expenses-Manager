class Account {
  final int? id;
  final String name;
  final String currency;
  final int color; // Store color as int value

  Account({
    this.id,
    required this.name,
    required this.currency,
    required this.color,
  });

  // Convert Account to Map for database insertion
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'currency': currency, 'color': color};
  }

  // Create Account from Map (database query result)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      currency: map['currency'] as String,
      color: map['color'] as int,
    );
  }

  // Create a copy of Account with some fields updated
  Account copyWith({int? id, String? name, String? currency, int? color}) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      color: color ?? this.color,
    );
  }
}
