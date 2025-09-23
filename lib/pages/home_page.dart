import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/grade_controller.dart';
import '../models/subject.dart';

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
      appBar: AppBar(title: Text('Input Nilai')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Masukkan ID Siswa',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final id = int.tryParse(idController.text);
                    if (id != null) studentCtrl.fetchStudentById(id);
                  },
                ),
              ),
            ),
            Obx(() {
              final student = studentCtrl.student.value;
              if (student == null) return Text('Data siswa belum ada');
              return Card(
                child: ListTile(
                  title: Text(student.name),
                  subtitle: Text(
                    student.className != null
                        ? 'Kelas: ${student.className}'
                        : 'Kelas ID: ${student.classId}',
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Obx(() {
              return DropdownButton<Subject>(
                hint: Text('Pilih Mata Pelajaran'),
                value: selectedSubject.value,
                onChanged: (val) {
                  selectedSubject.value = val;
                },
                items: subjectCtrl.subjects
                    .map(
                      (subj) =>
                          DropdownMenuItem(value: subj, child: Text(subj.name)),
                    )
                    .toList(),
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nilai'),
            ),
            const SizedBox(height: 20),
            Obx(() {
              return ElevatedButton(
                onPressed: gradeCtrl.isLoading.value
                    ? null
                    : () {
                        final student = studentCtrl.student.value;
                        final subject = selectedSubject.value;
                        final grade = double.tryParse(gradeController.text);
                        if (student != null &&
                            subject != null &&
                            grade != null) {
                          gradeCtrl.uploadGrade(
                            studentId: student.id,
                            subjectId: subject.id,
                            grade: grade,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Lengkapi data siswa, mapel, dan nilai',
                          );
                        }
                      },
                child: gradeCtrl.isLoading.value
                    ? CircularProgressIndicator()
                    : Text('Upload Nilai'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
