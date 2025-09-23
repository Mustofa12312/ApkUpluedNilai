class Student {
  final int id;
  final String name;
  final int classId;
  final String? className; // tambahkan ini

  Student({
    required this.id,
    required this.name,
    required this.classId,
    this.className,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'],
    classId: json['class_id'],
    className: json['classes'] != null ? json['classes']['name'] : null,
  );
}
