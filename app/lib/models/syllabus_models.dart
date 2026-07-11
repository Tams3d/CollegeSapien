class CurriculumSubject {
  final String collegeCode;
  final String courseCode;
  final String regulation;
  final int? semester;
  final String subjectCode;
  final String subjectName;
  final num? credits;
  final String category;
  final String? electiveType;
  final String recordType;

  CurriculumSubject({
    required this.collegeCode,
    required this.courseCode,
    required this.regulation,
    this.semester,
    required this.subjectCode,
    required this.subjectName,
    this.credits,
    required this.category,
    this.electiveType,
    this.recordType = 'core',
  });

  factory CurriculumSubject.fromJson(Map<String, dynamic> json) {
    return CurriculumSubject(
      collegeCode: json['college_code'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      regulation: json['regulation'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt(),
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      credits: json['credits'] as num?,
      category: json['category'] as String? ?? '',
      electiveType: json['elective_type'] as String?,
      recordType: json['record_type'] as String? ?? 'core',
    );
  }

  bool get isElective => recordType == 'elective' || recordType == 'option';
  bool get isElectiveSlot => recordType == 'elective';
  bool get isOption => recordType == 'option';
  bool get isCore => recordType == 'core';
}

class CurriculumBundle {
  final String collegeCode;
  final String courseCode;
  final String regulation;
  final List<String> availableRegulations;
  final List<CurriculumSubject> subjects;

  CurriculumBundle({
    required this.collegeCode,
    required this.courseCode,
    required this.regulation,
    required this.availableRegulations,
    required this.subjects,
  });

  factory CurriculumBundle.fromJson(Map<String, dynamic> json) {
    final subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    return CurriculumBundle(
      collegeCode: json['collegeCode'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      regulation: json['regulation'] as String? ?? '',
      availableRegulations: (json['availableRegulations'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
      subjects: subjectsJson
          .map((s) => CurriculumSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedSyllabus {
  final String? regulation;
  final List<SavedSubject> subjects;

  SavedSyllabus({this.regulation, required this.subjects});

  static SavedSyllabus? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final subjects = json['subjects'] as List<dynamic>?;
    if (subjects == null || subjects.isEmpty) return null;
    return SavedSyllabus(
      regulation: json['regulation'] as String?,
      subjects: subjects
          .map((s) => SavedSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedSubject {
  final String subjectCode;
  final String subjectName;
  final num? credits;
  final String? electiveType;
  final bool isElective;
  final String? category;

  SavedSubject({
    required this.subjectCode,
    required this.subjectName,
    this.credits,
    this.electiveType,
    this.isElective = false,
    this.category,
  });

  factory SavedSubject.fromJson(Map<String, dynamic> json) {
    return SavedSubject(
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: json['credits'] as num?,
      electiveType: json['electiveType'] as String?,
      isElective: json['isElective'] as bool? ?? false,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'credits': credits,
        'isElective': isElective,
        if (electiveType != null) 'electiveType': electiveType,
        if (category != null) 'category': category,
      };
}
