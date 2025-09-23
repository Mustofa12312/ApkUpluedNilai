import 'package:get/get.dart';
import '../models/subject.dart';
import '../services/supabase_service.dart';

class SubjectController extends GetxController {
  var subjects = <Subject>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final response =
        await SupabaseService.client.from('subjects').select();
    subjects.value =
        (response as List).map((e) => Subject.fromJson(e)).toList();
  }
}
