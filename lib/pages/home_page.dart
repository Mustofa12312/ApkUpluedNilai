import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/grade_controller.dart';
import '../models/subject.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class HomePage extends StatelessWidget {
  final studentCtrl = Get.put(StudentController());
  final subjectCtrl = Get.put(SubjectController());
  final gradeCtrl = Get.put(GradeController());

  final idController = TextEditingController();
  final gradeController = TextEditingController();
  final Rx<Subject?> selectedSubject = Rx<Subject?>(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'INPUT NILAI LPNS',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Masukkan ID Murid',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final id = int.tryParse(idController.text);
                    if (id != null) studentCtrl.fetchStudentById(id);
                  },
                ),
              ),
              onSubmitted: (value) {
                // ⬅️ ini yang ditambahkan
                final id = int.tryParse(value);
                if (id != null) studentCtrl.fetchStudentById(id);
              },
            ),
            SizedBox(height: 13),
            Obx(() {
              final student = studentCtrl.student.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: student == null
                    ? Text('Data siswa belum ada', key: ValueKey('noData'))
                    : Card(
                        key: ValueKey(student.id),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.amberAccent.withOpacity(0.4),
                        child: ListTile(
                          title: Text(
                            student.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            student.className != null
                                ? 'Kelas: ${student.className}'
                                : 'Kelas ID: ${student.classId}',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ),
              );
            }),

            const SizedBox(height: 20),

            Obx(() {
              return DropdownButtonFormField2<Subject>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Mata Pelajaran",
                  labelStyle: TextStyle(color: Colors.amber),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.amber),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                hint: Text(
                  'Pilih Mata Pelajaran',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                value: selectedSubject.value,
                onChanged: (val) {
                  selectedSubject.value = val;
                },
                items: subjectCtrl.subjects
                    .map(
                      (subj) => DropdownMenuItem<Subject>(
                        value: subj,
                        child: Text(
                          subj.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                    .toList(),

                // 🔽 Styling tambahan modern
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down, color: Colors.amber),
                ),
                buttonStyleData: ButtonStyleData(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 250, // biar list ga terlalu panjang
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 45,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              );
            }),

            const SizedBox(height: 20),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nilai'),
            ),
            const SizedBox(height: 20),
            Obx(
              () => AnimatedScale(
                scale: gradeCtrl.isLoading.value ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    onPressed: gradeCtrl.isLoading.value
                        ? null
                        : () {
                            final student = studentCtrl.student.value;
                            final subject = selectedSubject.value;
                            final grade = double.tryParse(gradeController.text);
                            if (student != null &&
                                subject != null &&
                                grade != null) {
                              gradeCtrl
                                  .uploadGrade(
                                    studentId: student.id,
                                    subjectId: subject.id,
                                    grade: grade,
                                  )
                                  .then((_) {
                                    idController.clear();
                                    gradeController.clear();
                                    studentCtrl.student.value = null;
                                  });
                            } else {
                              Get.snackbar(
                                'Error',
                                'Lengkapi data siswa, mapel, dan nilai',
                              );
                            }
                          },
                    child: gradeCtrl.isLoading.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Mengupload...",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Upload Nilai',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
