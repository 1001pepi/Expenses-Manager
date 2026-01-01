class Expense {
  final int? id;
  final int accountId;
  final int categoryId;
  final double amount;
  final DateTime date;
  final String tags; // Comma-separated tags
  final String? comment;
  final String? photo1Path; // Path to first photo
  final String? photo2Path; // Path to second photo
  final DateTime createdAt;

  Expense({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    required this.tags,
    this.comment,
    this.photo1Path,
    this.photo2Path,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'tags': tags,
      'comment': comment,
      'photo1Path': photo1Path,
      'photo2Path': photo2Path,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      accountId: map['accountId'] as int,
      categoryId: map['categoryId'] as int,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      tags: map['tags'] as String,
      comment: map['comment'] as String?,
      photo1Path: map['photo1Path'] as String?,
      photo2Path: map['photo2Path'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Expense copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    double? amount,
    DateTime? date,
    String? tags,
    String? comment,
    String? photo1Path,
    String? photo2Path,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      photo1Path: photo1Path ?? this.photo1Path,
      photo2Path: photo2Path ?? this.photo2Path,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
