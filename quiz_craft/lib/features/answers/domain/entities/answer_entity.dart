class AnswerEntity {
  final String id;
  final String text;
  final bool isCorrect;

  AnswerEntity({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory AnswerEntity.fromMap(Map<String, dynamic> map) {
    return AnswerEntity(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'is_correct': isCorrect,
      };
}
