import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class NoFinalGradePage extends StatefulWidget {
  const NoFinalGradePage({Key? key}) : super(key: key);

  @override
  State<NoFinalGradePage> createState() => _NoFinalGradePageState();
}

class _NoFinalGradePageState extends State<NoFinalGradePage> {
  final students = <Map<String, dynamic>>[].obs;
  final classes = <Map<String, dynamic>>[].obs;
  final subjects = <Map<String, dynamic>>[].obs;

  final selectedClassId = ''.obs;
  final selectedSubjectId = ''.obs;
  final isLoading = false.obs;

  final FocusNode classFocus = FocusNode();
  final FocusNode subjectFocus = FocusNode();

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
      final gradeIdsResponse = await SupabaseService.client
          .from('grades_ujian_akhir')
          .select('student_id')
          .eq('subject_id', int.parse(selectedSubjectId.value));

      final gradeIds = (gradeIdsResponse as List)
          .map((e) => e['student_id'])
          .where((id) => id != null)
          .toList();

      final result = await SupabaseService.client
          .from('students_ujian_akhir')
          .select('id, name, class_id, classes(name)')
          .eq('class_id', int.parse(selectedClassId.value))
          .not('id', 'in', gradeIds.isEmpty ? [0] : gradeIds)
          .order('name', ascending: true);

      students.assignAll(List<Map<String, dynamic>>.from(result));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Tanpa Nilai Ujian",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown Kelas
              Obx(() {
                return _glassField(
                  focusNode: classFocus,
                  child: DropdownButtonFormField<String>(
                    value: selectedClassId.value.isEmpty
                        ? null
                        : selectedClassId.value,
                    dropdownColor: Colors.black87,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Pilih Kelas",
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    items: classes
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(
                              c['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedClassId.value = val ?? '',
                  ),
                );
              }),
              const SizedBox(height: 3),

              // Dropdown Pelajaran
              Obx(() {
                return _glassField(
                  focusNode: subjectFocus,
                  child: DropdownButtonFormField<String>(
                    value: selectedSubjectId.value.isEmpty
                        ? null
                        : selectedSubjectId.value,
                    dropdownColor: Colors.black87,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Pilih Pelajaran",
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s['id'].toString(),
                            child: Text(
                              s['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedSubjectId.value = val ?? '',
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Tombol Cari
              Obx(
                () => SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: Text(
                      "Cari Murid",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading.value
                        ? null
                        : fetchStudentsWithoutGrades,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // List Siswa
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
                        "Tidak ada siswa yang belum memiliki nilai ujian akhir.",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 16,
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
                      final className = (s['classes']?['name'] ?? '-')
                          .toString();
                      final subjectName = _getSubjectNameById(
                        selectedSubjectId.value,
                      );
                      final id = s['id']?.toString() ?? '-';

                      return _glassField(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
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
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '$className\nPelajaran: $subjectName',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          trailing: Text(
                            'ID: $id',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
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
      ),
    );
  }

  Widget _glassField({required Widget child, FocusNode? focusNode}) {
    final isFocused = focusNode?.hasFocus ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isFocused ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(isFocused ? 0.4 : 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
