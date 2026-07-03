import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/syllabus_models.dart';
import 'api_service.dart';

class SyllabusService {
  Future<CurriculumBundle> getCurriculum({
    required String collegeCode,
    required String courseCode,
    String? regulation,
  }) async {
    final cacheKey =
        'curriculum_${collegeCode}_${courseCode}_${regulation ?? 'latest'}';
    final prefs = await SharedPreferences.getInstance();

    try {
      final query = StringBuffer(
          '/curriculum?collegeCode=$collegeCode&courseCode=$courseCode');
      if (regulation != null) query.write('&regulation=$regulation');

      final json =
          await ApiService.instance.get(query.toString()) as Map<String, dynamic>;
      await prefs.setString(cacheKey, jsonEncode(json));
      return CurriculumBundle.fromJson(json);
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return CurriculumBundle.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  List<CurriculumSubject> getSubjectsForSemester(
    CurriculumBundle bundle, {
    required int semester,
  }) {
    return bundle.subjects
        .where((s) => s.effectiveSemester == semester && !s.isOption)
        .toList();
  }

  List<CurriculumSubject> getElectiveOptions(
    CurriculumBundle bundle, {
    required String electiveType,
  }) {
    return bundle.subjects
        .where((s) => s.isOption && s.electiveType == electiveType)
        .toList();
  }

  Future<SavedSyllabus?> getSavedSyllabus(int semester) async {
    try {
      final json = await ApiService.instance
          .get('/syllabus/subjects/$semester') as Map<String, dynamic>;
      final subjects = json['subjects'] as List<dynamic>?;
      if (subjects == null || subjects.isEmpty) return null;
      return SavedSyllabus(
        regulation: json['regulation'] as String?,
        subjects: subjects
            .map((s) => SavedSubject.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<SavedSubject>?> getSavedSubjects(int semester) async {
    final saved = await getSavedSyllabus(semester);
    return saved?.subjects;
  }

  Future<void> saveSubjects({
    required int semester,
    required String regulation,
    required List<SavedSubject> subjects,
  }) async {
    await ApiService.instance.post('/syllabus/subjects', {
      'semester': semester,
      'regulation': regulation,
      'subjects': subjects.map((s) => s.toJson()).toList(),
    });
  }
}
