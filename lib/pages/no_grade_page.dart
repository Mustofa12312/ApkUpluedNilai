import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class NoGradePage extends StatefulWidget {
  const NoGradePage({Key? key}) : super(key: key);

  @override
  State<NoGradePage> createState() => _NoGradePageState();
}

class _NoGradePageState extends State<NoGradePage> {
  final students = <Map<String, dynamic>>[].obs;
  final classes = <Map<String, dynamic>>[].obs;
  final subjects = <Map<String, dynamic>>[].obs;

  final selectedClassId = ''.obs;
  final selectedSubjectId = ''.obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchSubjects();
  }

  Future<void> fetchClasses() async {
    try {
      final response = await SupabaseService.client.from('classes').select();
      classes.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat kelas: $e');
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final response = await SupabaseService.client.from('subjects').select();
      subjects.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat pelajaran: $e');
    }
  }

  String _getSubjectNameById(String id) {
    try {
      final m = subjects.firstWhere((s) => s['id'].toString() == id);
      return m['name'] ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<void> fetchStudentsWithoutGrades() async {
    if (selectedClassId.value.isEmpty || selectedSubjectId.value.isEmpty) {
      Get.snackbar('Peringatan', 'Pilih kelas dan pelajaran terlebih dahulu');
      return;
    }

    isLoading.value = true;
    try {
      // ambil semua student_id yang sudah punya nilai untuk subject terpilih
      final gradeIdsResponse = await SupabaseService.client
          .from('grades')
          .select('student_id')
          .eq('subject_id', int.parse(selectedSubjectId.value));

      final gradeIds = (gradeIdsResponse as List)
          .map((e) => e['student_id'])
          .where((id) => id != null)
          .toList();

      // ambil siswa di kelas yang belum punya nilai pada pelajaran itu
      final result = await SupabaseService.client
          .from('students')
          .select('id, name, class_id, classes(name)')
          .eq('class_id', int.parse(selectedClassId.value))
          .not('id', 'in', gradeIds.isEmpty ? [0] : gradeIds)
          .order('name', ascending: true);

      students.assignAll(List<Map<String, dynamic>>.from(result));
      debugPrint('DEBUG - Data siswa tanpa nilai: $students');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          "Murid Tanpa Nilai",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // kelas
            Obx(
              () => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Pilih Kelas",
                  border: OutlineInputBorder(),
                ),
                value: selectedClassId.value.isEmpty
                    ? null
                    : selectedClassId.value,
                items: classes
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) => selectedClassId.value = val ?? '',
              ),
            ),
            const SizedBox(height: 12),

            // pelajaran
            Obx(
              () => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Pilih Pelajaran",
                  border: OutlineInputBorder(),
                ),
                value: selectedSubjectId.value.isEmpty
                    ? null
                    : selectedSubjectId.value,
                items: subjects
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s['id'].toString(),
                        child: Text(s['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) => selectedSubjectId.value = val ?? '',
              ),
            ),
            const SizedBox(height: 14),

            // tombol cari
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  label: Text(
                    "Cari Murid",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading.value
                      ? null
                      : fetchStudentsWithoutGrades,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // hasil
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                }
                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      "Pangaporah kaintoh \n nyoonah pasteakih Kelas sareng Pengajeren ampon sesui dengan se imput, Ngereng pedih mulai",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final name = (s['name'] ?? '').toString();
                    final className = (s['classes']?['name'] ?? '-').toString();
                    final subjectName = _getSubjectNameById(
                      selectedSubjectId.value,
                    );
                    final id = s['id']?.toString() ?? '-';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber[400],
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name.isNotEmpty ? name : '(Tanpa Nama)',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '$className\nPelajaran: $subjectName',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        trailing: Text(
                          'ID: $id',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
