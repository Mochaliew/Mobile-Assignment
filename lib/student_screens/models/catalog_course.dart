// --- Catalog Models ----------------------------------------------------------
class LessonItem {
  final String title;
  final String subtitle;
  const LessonItem({required this.title, required this.subtitle});
}

class AssessmentItem {
  final String title;
  final String passingMarks;
  final String deadline;
  const AssessmentItem({
    required this.title,
    required this.passingMarks,
    required this.deadline,
  });
}

class FinalExamItem {
  final String examDate;
  final String description;
  const FinalExamItem({required this.examDate, required this.description});
}

class CatalogCourse {
  int id;
  String title;
  String instructor;
  String description;
  double price;
  double progress;
  bool isPurchased;
  final List<LessonItem> lessons;
  final List<AssessmentItem> assessments;
  final FinalExamItem? finalExam;

  CatalogCourse({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.price,
    required this.progress,
    required this.isPurchased,
    required this.lessons,
    required this.assessments,
    this.finalExam,
  });
}
