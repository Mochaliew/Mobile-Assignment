// ---- Session ----------------------------------------------------------------
class TeacherSession {
  static int? teacherId;
  static String? teacherName;
  static String? teacherEmail;

  static void clear() {
    teacherId = null;
    teacherName = null;
    teacherEmail = null;
  }
}

// --- User --------------------------------------------------------------------
class User {
  final int id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role; // Admin, Teacher, Student
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> map) => User(
    id: map['id'],
    fullName: map['full_name'] ?? '',
    email: map['email'] ?? '',
    passwordHash: map['password_hash'] ?? '',
    role: map['role'] ?? '',
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
  );
}

// --- Teacher -----------------------------------------------------------------
class Teacher {
  final int teacherId;
  final int userId;
  final String subjectArea;
  final bool isActive;

  Teacher({
    required this.teacherId,
    required this.userId,
    required this.subjectArea,
    required this.isActive,
  });

  factory Teacher.fromJson(Map<String, dynamic> map) => Teacher(
    teacherId: map['teacher_id'],
    userId: map['user_id'],
    subjectArea: map['subject_area'] ?? '',
    isActive: map['is_active'] ?? true,
  );
}

// --- Category ----------------------------------------------------------------
class Category {
  final int categoryId;
  final String name;

  Category({required this.categoryId, required this.name});

  factory Category.fromJson(Map<String, dynamic> map) => Category(
    categoryId: map['category_id'],
    name: map['name'] ?? '',
  );
}

// --- Course ------------------------------------------------------------------
class Course {
  final int courseId;
  final int teacherId;
  final int categoryId;
  final String categoryName;
  final String title;
  final String description;
  final double price;
  final bool isApproved;
  final bool isPublished;
  final bool isRejected;
  final String? rejectionReason;
  final int enrollmentCount;

  Course({
    required this.courseId,
    required this.teacherId,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    required this.isApproved,
    required this.isPublished,
    required this.isRejected,
    this.rejectionReason,
    this.enrollmentCount = 0,
  });

  factory Course.fromJson(Map<String, dynamic> map) => Course(
    courseId: map['course_id'],
    teacherId: map['teacher_id'],
    categoryId: map['category_id'] ?? 0,
    categoryName: map['categories']?['name'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    isApproved: map['is_approved'] ?? false,
    isPublished: map['is_published'] ?? false,
    isRejected: map['is_rejected'] ?? false,
    rejectionReason: map['rejection_reason'],
    enrollmentCount: (map['enrollments'] as List?)?.length ?? 0,
  );
}

// --- CourseFile --------------------------------------------------------------
class CourseFile {
  final int courseFileId;
  final int lessonId;
  final String filePath;
  final String fileType; // 'pdf' | 'video'
  final DateTime uploadedAt;

  CourseFile({
    required this.courseFileId,
    required this.lessonId,
    required this.filePath,
    required this.fileType,
    required this.uploadedAt,
  });

  factory CourseFile.fromJson(Map<String, dynamic> map) => CourseFile(
    courseFileId: map['course_file_id'],
    lessonId: map['lesson_id'],
    filePath: map['file_path'] ?? '',
    fileType: map['file_type'] ?? '',
    uploadedAt: DateTime.tryParse(map['update_at'] ?? '') ?? DateTime.now(),
  );
}

// --- Lesson ------------------------------------------------------------------
class Lesson {
  final int lessonId;
  final int courseId;
  final String courseName;
  final String title;
  final String description;
  final String meetLink;
  final DateTime? scheduleDate;
  final List<CourseFile> files;

  Lesson({
    required this.lessonId,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.meetLink,
    this.scheduleDate,
    this.files = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> map) => Lesson(
    lessonId: map['lesson_id'],
    courseId: map['course_id'],
    // joined via .select('*, courses(title)')
    courseName: map['courses']?['title'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    meetLink: map['meet_link'] ?? '',
    scheduleDate: map['schedule_date'] != null
        ? DateTime.tryParse(map['schedule_date'])
        : null,
  );
}

// --- Question ----------------------------------------------------------------
class Question {
  final int questionId;
  final String questionDetail;
  final String answerA;
  final String answerB;
  final String answerC;
  final String answerD;
  final String correctAnswer;

  Question({
    required this.questionId,
    required this.questionDetail,
    required this.answerA,
    required this.answerB,
    required this.answerC,
    required this.answerD,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> map) => Question(
    // assessment_questions uses question_id, final_questions uses final_question_id
    questionId: map['question_id'] ?? map['final_question_id'] ?? 0,
    questionDetail: map['question_detail'] ?? '',
    answerA: map['answer_a'] ?? '',
    answerB: map['answer_b'] ?? '',
    answerC: map['answer_c'] ?? '',
    answerD: map['answer_d'] ?? '',
    correctAnswer: map['correct_answer'] ?? '',
  );
}

// --- Assessment --------------------------------------------------------------
class Assessment {
  final int assessmentId;
  final int courseId;
  final String courseName;
  final String title;
  final int totalMarks;
  final int passingMark;
  final DateTime deadline;
  final List<Question> questions;

  Assessment({
    required this.assessmentId,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.totalMarks,
    required this.passingMark,
    required this.deadline,
    this.questions = const [],
  });

  factory Assessment.fromJson(Map<String, dynamic> map) => Assessment(
    assessmentId: map['assessment_id'],
    courseId: map['course_id'],
    courseName: map['courses']?['title'] ?? '',
    title: map['title'] ?? '',
    totalMarks: map['total_marks'] ?? 0,
    passingMark: map['passing_mark'] ?? 70,
    deadline: DateTime.tryParse(map['dead_line'] ?? '') ?? DateTime.now(),
  );
}

// --- FinalExam ---------------------------------------------------------------
class FinalExam {
  final int finalId;
  final int courseId;
  final String courseName;
  final String title;
  final int totalMarks;
  final int passingMark;
  final DateTime deadline;
  final List<Question> questions;

  FinalExam({
    required this.finalId,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.totalMarks,
    required this.passingMark,
    required this.deadline,
    this.questions = const [],
  });

  factory FinalExam.fromJson(Map<String, dynamic> map) => FinalExam(
    finalId: map['final_id'],
    courseId: map['course_id'],
    courseName: map['courses']?['title'] ?? '',
    title: map['title'] ?? '',
    totalMarks: map['total_marks'] ?? 0,
    passingMark: map['passing_mark'] ?? 70,
    deadline: DateTime.tryParse(map['dead_line'] ?? '') ?? DateTime.now(),
  );
}

// --- question form -----------------------------------------------------------
class QuestionForm {
  String questionDetail = '';
  String answerA = '';
  String answerB = '';
  String answerC = '';
  String answerD = '';
  String correctAnswer = ''; // 'A' | 'B' | 'C' | 'D'
}
