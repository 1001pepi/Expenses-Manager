class Category {
  final int? id;
  final String name;
  final int iconCode;
  final int color;

  Category({
    this.id,
    required this.name,
    required this.iconCode,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'iconCode': iconCode, 'color': color};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['iconCode'] as int,
      color: map['color'] as int,
    );
  }

  Category copyWith({int? id, String? name, int? iconCode, int? color}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      color: color ?? this.color,
    );
  }
}
