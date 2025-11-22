class AnswerEntity {
  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnswerEntity({
    required this.id,
    required this.questionId,
    required this.text,
    this.isCorrect = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  factory AnswerEntity.fromMap(Map<String, dynamic> map) {
    final createdAt = map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now();
    final updatedAt = map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? createdAt : createdAt;

    return AnswerEntity(
      id: map['id']?.toString() ?? '',
      questionId: map['question_id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question_id': questionId,
        'text': text,
        'is_correct': isCorrect,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
