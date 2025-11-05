import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController idController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  final Rxn<Map<String, dynamic>> studentData = Rxn<Map<String, dynamic>>();
  final RxBool isLoading = false.obs;
  final RxBool isSubjectsLoading = false.obs;
  final RxList<Map<String, dynamic>> subjects = <Map<String, dynamic>>[].obs;
  final RxnInt selectedSubjectId = RxnInt();

  final FocusNode idFocus = FocusNode();
  final FocusNode gradeFocus = FocusNode();

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  bool _btnPressed = false;

  @override
  void initState() {
    super.initState();
    fetchSubjects();

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(fadeAnimation);

    ever(studentData, (data) {
      if (data != null) fadeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    idController.dispose();
    gradeController.dispose();
    idFocus.dispose();
    gradeFocus.dispose();
    fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchSubjects() async {
    try {
      isSubjectsLoading.value = true;
      final response = await SupabaseService.client
          .from('subjects')
          .select('id, name');
      subjects.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat daftar pelajaran: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSubjectsLoading.value = false;
    }
  }

  Future<void> fetchStudentById() async {
    final idText = idController.text.trim();
    if (idText.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Masukkan ID siswa terlebih dahulu',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    FocusScope.of(context).unfocus(); // ✅ Tutup keyboard otomatis

    try {
      isLoading.value = true;
      final response = await SupabaseService.client
          .from('students_kuartal')
          .select('id, name, class_id, classes(name)')
          .eq('id', int.parse(idText))
          .maybeSingle();

      if (response != null) {
        studentData.value = response;

        // ✅ Fokus otomatis ke kolom nilai setelah muncul
        Future.delayed(const Duration(milliseconds: 350), () {
          gradeFocus.requestFocus();
        });
      } else {
        studentData.value = null;
        Get.snackbar(
          'Info',
          'Siswa dengan ID $idText tidak ditemukan',
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadGrade() async {
    if (studentData.value == null) {
      Get.snackbar(
        'Error',
        'Cari siswa terlebih dahulu',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (gradeController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan nilai terlebih dahulu',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (selectedSubjectId.value == null) {
      Get.snackbar(
        'Error',
        'Pilih mata pelajaran terlebih dahulu',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    final gradeValue = double.tryParse(gradeController.text);
    if (gradeValue == null || gradeValue < 0 || gradeValue > 100) {
      // ✅ Validasi nilai
      Get.snackbar(
        'Input tidak valid',
        'Masukkan angka antara 0–100',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await SupabaseService.client.from('grades_kuartal').insert({
        'student_id': studentData.value!['id'],
        'subject_id': selectedSubjectId.value,
        'grade': gradeValue,
      });

      Get.snackbar(
        'Sukses',
        'Nilai berhasil diupload',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // ✅ Reset ID & Nilai, tapi mata pelajaran tetap terpilih
      idController.clear();
      gradeController.clear();
      studentData.value = null;
      idFocus.requestFocus();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "Input Nilai Kuartal",
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown Pelajaran
              Obx(() {
                if (isSubjectsLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                }
                return _glassField(
                  child: DropdownButtonFormField<int>(
                    value: selectedSubjectId.value,
                    dropdownColor: Colors.black87,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pilih Mata Pelajaran',
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    items: subjects.map((subj) {
                      return DropdownMenuItem<int>(
                        value: subj['id'],
                        child: Text(
                          subj['name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => selectedSubjectId.value = val,
                  ),
                );
              }),

              // Input ID Siswa
              _glassField(
                focusNode: idFocus,
                child: TextField(
                  controller: idController,
                  focusNode: idFocus,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.cyanAccent,
                  decoration: const InputDecoration(
                    hintText: "Masukkan ID Murid",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.white70),
                  ),
                  onSubmitted: (_) => fetchStudentById(),
                ),
              ),

              // Info siswa (fade + slide)
              Obx(() {
                if (isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                  );
                }
                if (studentData.value == null) return const SizedBox();

                final s = studentData.value!;
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: _glassField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] ?? '(Tanpa Nama)',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Kelas: ${s['classes']?['name'] ?? '-'}",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Input nilai
              _glassField(
                focusNode: gradeFocus,
                child: TextField(
                  controller: gradeController,
                  focusNode: gradeFocus,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.cyanAccent,
                  decoration: const InputDecoration(
                    hintText: "Masukkan Nilai Kuartal",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol responsif
              GestureDetector(
                onTapDown: (_) => setState(() => _btnPressed = true),
                onTapUp: (_) => setState(() => _btnPressed = false),
                onTapCancel: () => setState(() => _btnPressed = false),
                onTap: uploadGrade,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 48,
                  decoration: BoxDecoration(
                    color: _btnPressed
                        ? Colors.blueAccent.withOpacity(0.4)
                        : Colors.blueAccent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: _btnPressed ? 4 : 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Input Nilai',
                    style: TextStyle(
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

  Widget _glassField({required Widget child, FocusNode? focusNode}) {
    final isFocused = focusNode?.hasFocus ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isFocused ? 0.25 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isFocused ? 0.5 : 0.2),
              width: 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }
}
