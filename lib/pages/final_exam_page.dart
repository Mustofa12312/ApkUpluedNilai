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

class _FinalExamPageState extends State<FinalExamPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final idController = TextEditingController();
  final gradeController = TextEditingController();

  // Reactive states
  final studentData = Rxn<Map<String, dynamic>>();
  final subjects = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSubjectsLoading = false.obs;
  final selectedSubjectId = RxnInt();

  // Focus nodes
  final idFocus = FocusNode();
  final gradeFocus = FocusNode();

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSubjects();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    idController.dispose();
    gradeController.dispose();
    idFocus.dispose();
    gradeFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // 🔹 Fetch daftar mata pelajaran dari Supabase
  Future<void> _fetchSubjects() async {
    try {
      isSubjectsLoading.value = true;
      final response = await SupabaseService.client
          .from('subjects')
          .select('id, name');
      subjects.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat daftar pelajaran\n$e');
    } finally {
      isSubjectsLoading.value = false;
    }
  }

  // 🔹 Ambil data siswa berdasarkan ID
  Future<void> _fetchStudentById() async {
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
        _fadeController.forward(from: 0);

        // 🔹 Fokus otomatis ke kolom nilai setelah siswa ditemukan
        Future.delayed(const Duration(milliseconds: 250), () {
          FocusScope.of(context).requestFocus(gradeFocus);
        });
      } else {
        studentData.value = null;
        Get.snackbar('Info', 'Siswa dengan ID $idText tidak ditemukan');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data siswa\n$e');
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 Upload nilai ujian akhir ke Supabase
  Future<void> _uploadGrade() async {
    if (studentData.value == null) {
      Get.snackbar('Error', 'Cari siswa terlebih dahulu');
      return;
    }
    if (selectedSubjectId.value == null) {
      Get.snackbar('Error', 'Pilih mata pelajaran terlebih dahulu');
      return;
    }
    if (gradeController.text.isEmpty) {
      Get.snackbar('Error', 'Masukkan nilai ujian');
      return;
    }

    try {
      final gradeValue = double.tryParse(gradeController.text);
      if (gradeValue == null) {
        Get.snackbar('Error', 'Nilai harus berupa angka');
        return;
      }

      await SupabaseService.client.from('grades_ujian_akhir').insert({
        'student_id': studentData.value!['id'],
        'subject_id': selectedSubjectId.value,
        'grade': gradeValue,
      });

      // Reset input setelah upload
      idController.clear();
      gradeController.clear();
      studentData.value = null;
      FocusScope.of(context).requestFocus(idFocus);

      Get.snackbar('Sukses', 'Nilai ujian akhir berhasil diupload');
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengunggah nilai\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Input Nilai Ujian',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSubjectDropdown(),
              const SizedBox(height: 4),
              _buildIdInput(),
              const SizedBox(height: 4),
              _buildStudentInfo(),
              const SizedBox(height: 4),
              _buildGradeInput(),
              const SizedBox(height: 12),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Dropdown Mata Pelajaran
  Widget _buildSubjectDropdown() {
    return Obx(() {
      if (isSubjectsLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        );
      }

      return _glassField(
        child: DropdownButtonFormField<int>(
          value: selectedSubjectId.value,
          dropdownColor: Colors.black,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Pilih Mata Pelajaran',
            hintStyle: TextStyle(color: Colors.white70),
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
    });
  }

  // 🔹 Input ID Siswa
  Widget _buildIdInput() {
    return _glassField(
      focusNode: idFocus,
      child: TextField(
        controller: idController,
        focusNode: idFocus,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.indigoAccent,
        decoration: const InputDecoration(
          hintText: 'Masukkan ID Murid',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Colors.white),
        ),
        onSubmitted: (_) => _fetchStudentById(),
      ),
    );
  }

  // 🔹 Info Siswa
  Widget _buildStudentInfo() {
    return Obx(() {
      if (isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        );
      }

      if (studentData.value == null) return const SizedBox();

      final student = studentData.value!;

      return FadeTransition(
        opacity: _fadeAnimation,
        child: _glassField(
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
              const SizedBox(height: 2),
              Text(
                'Rayon: ${student['classes']?['name'] ?? '-'}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Madrasah: ${student['addresses']?['name'] ?? '(Belum diatur)'}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 🔹 Input Nilai
  Widget _buildGradeInput() {
    return _glassField(
      focusNode: gradeFocus,
      child: TextField(
        controller: gradeController,
        focusNode: gradeFocus,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.indigoAccent,
        decoration: const InputDecoration(
          hintText: 'Masukkan Nilai Ujian',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 🔹 Tombol Simpan
  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _uploadGrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.indigoAccent.withOpacity(0.5)),
          ),
          elevation: 6,
        ),
        child: const Text(
          'Simpan Nilai',
          style: TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 🔹 Wrapper efek kaca (glassmorphism)
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
