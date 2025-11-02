class GradeKuartal {
  final int id;
  final int studentId;
  final int subjectId;
  final double grade;

  GradeKuartal({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.grade,
  });

  factory GradeKuartal.fromJson(Map<String, dynamic> json) => GradeKuartal(
    id: json['id'],
    studentId: json['student_id'],
    subjectId: json['subject_id'],
    grade: (json['grade'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'subject_id': subjectId,
    'grade': grade,
  };
}
