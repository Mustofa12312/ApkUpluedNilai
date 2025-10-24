import 'package:get/get.dart';
import '../services/supabase_service.dart';

class NoGradeController extends GetxController {
  var isLoading = false.obs;
  var studentsWithoutGrade = [].obs;

  Future<void> fetchStudentsWithoutGrade(int classId, int subjectId) async {
    try {
      isLoading.value = true;

      // 🔹 Ambil semua student_id yang SUDAH punya nilai di mata pelajaran ini
      final existingGrades = await SupabaseService.client
          .from('grades')
          .select('student_id')
          .eq('subject_id', subjectId);

      final studentIdsWithGrades = (existingGrades as List)
          .map((e) => e['student_id'])
          .toList();

      // 🔹 Ambil siswa dari kelas yang BELUM ada di daftar studentIdsWithGrades
      final query = SupabaseService.client
          .from('students')
          .select('id, name')
          .eq('class_id', classId);

      if (studentIdsWithGrades.isNotEmpty) {
        query.not('id', 'in', studentIdsWithGrades);
      }

      final response = await query;

      studentsWithoutGrade.value = response;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
