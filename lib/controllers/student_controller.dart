import 'package:get/get.dart';
import '../models/student.dart';
import '../services/supabase_service.dart';

class StudentController extends GetxController {
  var student = Rxn<Student>();

  Future<void> fetchStudentById(int id) async {
    final response = await SupabaseService.client
        .from('students')
        // ambil juga data kelas terkait
        .select('id, name, class_id, classes ( name )')
        .eq('id', id)
        .maybeSingle();

    if (response != null) {
      student.value = Student.fromJson(response);
    } else {
      student.value = null;
    }
  }
}
