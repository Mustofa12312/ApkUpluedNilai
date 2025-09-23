import 'package:get/get.dart';
import '../services/supabase_service.dart';

class GradeController extends GetxController {
  var isLoading = false.obs;

  Future<void> uploadGrade({
    required int studentId,
    required int subjectId,
    required double grade,
  }) async {
    isLoading.value = true;
    try {
      await SupabaseService.client.from('grades').insert({
        'student_id': studentId,
        'subject_id': subjectId,
        'grade': grade,
      });
      Get.snackbar(
        'Sukses',
        'Nilai berhasil diupload',
        duration: Duration(milliseconds: 1100),
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
