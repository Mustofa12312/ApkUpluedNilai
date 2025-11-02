class StudentUjianAkhir {
  final int id;
  final String name;
  final int classId;
  final int? addressId;
  final String? addressName; // opsional untuk tampilkan nama alamat

  StudentUjianAkhir({
    required this.id,
    required this.name,
    required this.classId,
    this.addressId,
    this.addressName,
  });

  factory StudentUjianAkhir.fromJson(Map<String, dynamic> json) {
    return StudentUjianAkhir(
      id: json['id'],
      name: json['name'],
      classId: json['class_id'],
      addressId: json['address_id'],
      addressName: json['addresses']?['name'], // ambil dari relasi
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'class_id': classId, 'address_id': addressId};
  }
}
