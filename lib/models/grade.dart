class Grade {
  final int id; // id record grade
  final int studentId; // id siswa
  final int subjectId; // id mata pelajaran
  final double grade; // nilai

  Grade({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.grade,
  });

  // buat dari JSON Supabase
  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: json['id'],
    studentId: json['student_id'],
    subjectId: json['subject_id'],
    grade: (json['grade'] as num).toDouble(),
  );

  // ubah ke map saat mau insert/update ke Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'subject_id': subjectId,
    'grade': grade,
  };
}
