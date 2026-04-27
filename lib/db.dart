// --- Session -----------------------------------------------------------------
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
  final String role;
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
  final String fileType;
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

// --- QuestionForm ------------------------------------------------------------
class QuestionForm {
  String questionDetail = '';
  String answerA = '';
  String answerB = '';
  String answerC = '';
  String answerD = '';
  String correctAnswer = '';
}

// --- Admin Session -----------------------------------------------------------
class AdminSession {
  static int? adminId;
  static int? userId;
  static String? adminName;
  static String? adminEmail;

  static void clear() {
    adminId = null;
    userId = null;
    adminName = null;
    adminEmail = null;
  }
}

// --- Admin -------------------------------------------------------------------
class Admin {
  final int adminId;
  final int userId;
  final User? user;

  Admin({
    required this.adminId,
    required this.userId,
    this.user,
  });

  factory Admin.fromJson(Map<String, dynamic> map) => Admin(
    adminId: map['admin_id'],
    userId: map['user_id'],
    user: map['users'] != null ? User.fromJson(map['users']) : null,
  );
}

// --- Student -----------------------------------------------------------------
class Student {
  final int studentId;
  final int userId;
  final String? className;
  final DateTime enrollmentDate;
  final User? user;

  Student({
    required this.studentId,
    required this.userId,
    this.className,
    required this.enrollmentDate,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> map) => Student(
    studentId: map['student_id'],
    userId: map['user_id'],
    className: map['class_name'],
    enrollmentDate:
    DateTime.tryParse(map['enrollment_date'] ?? '') ?? DateTime.now(),
    user: map['users'] != null ? User.fromJson(map['users']) : null,
  );
}

// --- Audit Log ---------------------------------------------------------------
class AuditLog {
  final int auditLogId;
  final int? userId;
  final String action;
  final String? details;
  final DateTime timestamp;

  AuditLog({
    required this.auditLogId,
    this.userId,
    required this.action,
    this.details,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> map) => AuditLog(
    auditLogId: map['audit_log_id'],
    userId: map['user_id'],
    action: map['action'] ?? '',
    details: map['details'],
    timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
  );
}

// --- System Setting ----------------------------------------------------------
class SystemSetting {
  final int systemSettingId;
  final String platformName;
  final String? logoPath;
  final String primaryColor;
  final String? smtpHost;
  final int smtpPort;
  final String? senderEmail;
  final bool enableEmailNotification;
  final String storageType;
  final int maxUploadSizeMB;
  final String allowedFileTypes;
  final String? certificateTemplatePath;

  SystemSetting({
    required this.systemSettingId,
    required this.platformName,
    this.logoPath,
    required this.primaryColor,
    this.smtpHost,
    required this.smtpPort,
    this.senderEmail,
    required this.enableEmailNotification,
    required this.storageType,
    required this.maxUploadSizeMB,
    required this.allowedFileTypes,
    this.certificateTemplatePath,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> map) => SystemSetting(
    systemSettingId: map['system_setting_id'],
    platformName: map['platform_name'] ?? 'RSD E-Learning',
    logoPath: map['logo_path'],
    primaryColor: map['primary_color'] ?? '#0d6efd',
    smtpHost: map['smtp_host'],
    smtpPort: map['smtp_port'] ?? 587,
    senderEmail: map['sender_email'],
    enableEmailNotification: map['enable_email_notification'] ?? true,
    storageType: map['storage_type'] ?? 'Local',
    maxUploadSizeMB: map['max_upload_size_mb'] ?? 50,
    allowedFileTypes: map['allowed_file_types'] ?? '.pdf,.mp4,.docx',
    certificateTemplatePath: map['certificate_template_path'],
  );
}

// --- Enrollment --------------------------------------------------------------
class Enrollment {
  final int enrollmentId;
  final int studentId;
  final int courseId;
  final DateTime enrolledAt;
  final bool paymentStatus;
  final String paymentMethod;
  final double amountPaid;
  final Student? student;
  final Course? course;

  Enrollment({
    required this.enrollmentId,
    required this.studentId,
    required this.courseId,
    required this.enrolledAt,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.amountPaid,
    this.student,
    this.course,
  });

  factory Enrollment.fromJson(Map<String, dynamic> map) => Enrollment(
    enrollmentId: map['enrollment_id'],
    studentId: map['student_id'],
    courseId: map['course_id'],
    enrolledAt: DateTime.tryParse(map['enrolled_at'] ?? '') ?? DateTime.now(),
    paymentStatus: map['payment_status'] ?? false,
    paymentMethod: map['payment_method'] ?? '',
    amountPaid: (map['amount_paid'] ?? 0).toDouble(),
    student:
    map['students'] != null ? Student.fromJson(map['students']) : null,
    course: map['courses'] != null ? Course.fromJson(map['courses']) : null,
  );
}

// --- Payment Transaction -----------------------------------------------------
class PaymentTransaction {
  final int paymentTransactionId;
  final int studentId;
  final int courseId;
  final double amount;
  final String paymentMethod;
  final DateTime transactionDate;
  final Student? student;
  final Course? course;

  PaymentTransaction({
    required this.paymentTransactionId,
    required this.studentId,
    required this.courseId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionDate,
    this.student,
    this.course,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> map) =>
      PaymentTransaction(
        paymentTransactionId: map['payment_transaction_id'],
        studentId: map['student_id'],
        courseId: map['course_id'],
        amount: (map['amount'] ?? 0).toDouble(),
        paymentMethod: map['payment_method'] ?? 'FakeGateway',
        transactionDate:
        DateTime.tryParse(map['transaction_date'] ?? '') ?? DateTime.now(),
        student:
        map['students'] != null ? Student.fromJson(map['students']) : null,
        course: map['courses'] != null ? Course.fromJson(map['courses']) : null,
      );
}
