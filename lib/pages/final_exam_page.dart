import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class FinalExamPage extends StatefulWidget {
  const FinalExamPage({Key? key}) : super(key: key);

  @override
  State<FinalExamPage> createState() => _FinalExamPageState();
}

class _FinalExamPageState extends State<FinalExamPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  final Rxn<Map<String, dynamic>> studentData = Rxn<Map<String, dynamic>>();
  final RxBool isLoading = false.obs;
  final RxBool isSubjectsLoading = false.obs;

  final RxList<Map<String, dynamic>> subjects = <Map<String, dynamic>>[].obs;
  final RxnInt selectedSubjectId = RxnInt();

  final FocusNode idFocus = FocusNode();
  final FocusNode gradeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  @override
  void dispose() {
    idController.dispose();
    gradeController.dispose();
    idFocus.dispose();
    gradeFocus.dispose();
    super.dispose();
  }

  // 🔹 Ambil daftar mata pelajaran
  Future<void> fetchSubjects() async {
    try {
      isSubjectsLoading.value = true;
      final response = await SupabaseService.client
          .from('subjects')
          .select('id, name');
      subjects.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat daftar pelajaran: $e');
    } finally {
      isSubjectsLoading.value = false;
    }
  }

  // 🔹 Ambil data siswa berdasarkan ID
  Future<void> fetchStudentById() async {
    final idText = idController.text.trim();
    if (idText.isEmpty) {
      Get.snackbar('Peringatan', 'Masukkan ID siswa terlebih dahulu');
      return;
    }

    try {
      isLoading.value = true;
      final response = await SupabaseService.client
          .from('students_ujian_akhir')
          .select('id, name, class_id, classes(name), addresses(name)')
          .eq('id', int.parse(idText))
          .maybeSingle();

      if (response != null) {
        studentData.value = response;
      } else {
        studentData.value = null;
        Get.snackbar('Info', 'Siswa dengan ID $idText tidak ditemukan');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 Upload nilai ujian akhir
  Future<void> uploadGrade() async {
    if (studentData.value == null) {
      Get.snackbar('Error', 'Cari siswa terlebih dahulu');
      return;
    }
    if (gradeController.text.isEmpty) {
      Get.snackbar('Error', 'Masukkan nilai terlebih dahulu');
      return;
    }
    if (selectedSubjectId.value == null) {
      Get.snackbar('Error', 'Pilih mata pelajaran terlebih dahulu');
      return;
    }

    try {
      final gradeValue = double.parse(gradeController.text);
      await SupabaseService.client.from('grades_ujian_akhir').insert({
        'student_id': studentData.value!['id'],
        'subject_id': selectedSubjectId.value,
        'grade': gradeValue,
      });
      Get.snackbar('Sukses', 'Nilai ujian akhir berhasil diupload');
      gradeController.clear();
      selectedSubjectId.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "Input Nilai Ujian",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 Dropdown Mata Pelajaran
              Obx(() {
                if (isSubjectsLoading.value) {
                  return const CircularProgressIndicator(color: Colors.indigo);
                }
                return _glassField(
                  child: DropdownButtonFormField<int>(
                    value: selectedSubjectId.value == 0
                        ? null
                        : selectedSubjectId.value,
                    dropdownColor: Colors.black,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pilih Mata Pelajaran',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                    items: subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject['id'],
                        child: Text(
                          subject['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => selectedSubjectId.value = val,
                  ),
                );
              }),
              const SizedBox(height: 1),

              // 🔹 Input ID Siswa
              _glassField(
                focusNode: idFocus,
                child: TextField(
                  controller: idController,
                  focusNode: idFocus,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.indigoAccent,
                  decoration: const InputDecoration(
                    hintText: "Masukkan ID Murid",
                    hintStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.white),
                  ),
                  onSubmitted: (_) => fetchStudentById(),
                ),
              ),
              const SizedBox(height: 1),

              // 🔹 Info Siswa (Nama, Kelas, Alamat)
              Obx(() {
                if (isLoading.value) {
                  return const CircularProgressIndicator(color: Colors.indigo);
                }
                if (studentData.value == null) return const SizedBox();
                final student = studentData.value!;
                return _glassField(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '(Tanpa Nama)',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "Rayon: ${student['classes']?['name'] ?? '-'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 0),
                      Text(
                        "Madrasah: ${student['addresses']?['name'] ?? '(Belum diatur)'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 1),

              // 🔹 Input Nilai
              _glassField(
                focusNode: gradeFocus,
                child: TextField(
                  controller: gradeController,
                  focusNode: gradeFocus,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.indigoAccent,
                  decoration: const InputDecoration(
                    hintText: "Masukkan Nilai Ujian",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Tombol Simpan
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.indigoAccent.withOpacity(0.5),
                      ),
                    ),
                    elevation: 6,
                  ),
                  onPressed: uploadGrade,
                  child: const Text(
                    'Simpan Nilai',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Glass Effect Field Wrapper
  Widget _glassField({required Widget child, FocusNode? focusNode}) {
    final isFocused = focusNode?.hasFocus ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isFocused ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
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
