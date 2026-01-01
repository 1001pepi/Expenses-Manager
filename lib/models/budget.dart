class Budget {
  final int? id;
  final int accountId;
  final int categoryId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String tags; // Comma-separated tags
  final String? comment;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.tags,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'tags': tags,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      accountId: map['accountId'] as int,
      categoryId: map['categoryId'] as int,
      amount: map['amount'] as double,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      tags: map['tags'] as String,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Budget copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    String? tags,
    String? comment,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
