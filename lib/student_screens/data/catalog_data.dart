// --- Hardcoded Catalog Data --------------------------------------------------
import '../models/catalog_course.dart';

List<CatalogCourse> getMockCourses() {
  return [
    CatalogCourse(
      id: 1,
      title: 'Introduction to React',
      instructor: 'Sarah Johnson',
      description:
          'Learn the fundamentals of React including components, props, state, and hooks. Build modern web applications with confidence.',
      price: 49.99,
      progress: 0.65,
      isPurchased: true,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: Getting Started',
          subtitle: 'Introduction to React and setup',
        ),
        const LessonItem(
          title: 'Chapter 2: Components',
          subtitle: 'Understanding React components',
        ),
        const LessonItem(
          title: 'Chapter 3: Hooks',
          subtitle: 'useState, useEffect, and custom hooks',
        ),
        const LessonItem(
          title: 'Chapter 4: Advanced Patterns',
          subtitle: 'Context API and performance',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'Mid-term Quiz',
          passingMarks: '70%',
          deadline: 'May 5, 2026',
        ),
        const AssessmentItem(
          title: 'Final Project',
          passingMarks: '80%',
          deadline: 'May 20, 2026',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'May 25, 2026',
        description: 'Comprehensive exam covering all course materials',
      ),
    ),
    CatalogCourse(
      id: 2,
      title: 'Python for Data Science',
      instructor: 'Dr. Michael Chen',
      description:
          'Master Python programming for data analysis, visualization, and machine learning.',
      price: 79.99,
      progress: 0.40,
      isPurchased: true,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: Python Basics',
          subtitle: 'Variables, data types, and control flow',
        ),
        const LessonItem(
          title: 'Chapter 2: Data Analysis',
          subtitle: 'Pandas and NumPy fundamentals',
        ),
        const LessonItem(
          title: 'Chapter 3: Visualization',
          subtitle: 'Matplotlib and Seaborn',
        ),
        const LessonItem(
          title: 'Chapter 4: Machine Learning',
          subtitle: 'Scikit-learn basics',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'Week 2 Assignment',
          passingMarks: '60%',
          deadline: 'Apr 30, 2026',
        ),
        const AssessmentItem(
          title: 'Final Exam',
          passingMarks: '75%',
          deadline: 'May 15, 2026',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'May 15, 2026',
        description: 'Comprehensive Python and data science exam',
      ),
    ),
    CatalogCourse(
      id: 3,
      title: 'UI/UX Design Fundamentals',
      instructor: 'Emma Williams',
      description:
          'Create beautiful and intuitive user interfaces. Master design principles, wireframing, and prototyping.',
      price: 59.99,
      progress: 1.0,
      isPurchased: true,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: Design Principles',
          subtitle: 'Color, typography, and layout',
        ),
        const LessonItem(
          title: 'Chapter 2: Wireframing',
          subtitle: 'Low and high fidelity wireframes',
        ),
        const LessonItem(
          title: 'Chapter 3: Prototyping',
          subtitle: 'Interactive prototypes with Figma',
        ),
        const LessonItem(
          title: 'Chapter 4: User Testing',
          subtitle: 'Usability testing methods',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'Design Project',
          passingMarks: '70%',
          deadline: 'Mar 10, 2026',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'Mar 15, 2026',
        description: 'Design a complete mobile app interface',
      ),
    ),
    CatalogCourse(
      id: 4,
      title: 'Advanced JavaScript',
      instructor: 'Alex Rodriguez',
      description:
          'Deep dive into JavaScript including async programming, closures, prototypes, and modern ES6+ features.',
      price: 0,
      progress: 0,
      isPurchased: false,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: Advanced Functions',
          subtitle: 'Closures and higher-order functions',
        ),
        const LessonItem(
          title: 'Chapter 2: Async JavaScript',
          subtitle: 'Promises, async/await',
        ),
        const LessonItem(
          title: 'Chapter 3: ES6+ Features',
          subtitle: 'Modern JavaScript syntax',
        ),
        const LessonItem(
          title: 'Chapter 4: Performance',
          subtitle: 'Optimization techniques',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'Coding Challenge',
          passingMarks: '80%',
          deadline: 'TBD',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'TBD',
        description: 'Build a complex JavaScript application',
      ),
    ),
    CatalogCourse(
      id: 5,
      title: 'Mobile App Development',
      instructor: 'Lisa Park',
      description:
          'Build native mobile applications for iOS and Android using Flutter and React Native.',
      price: 89.99,
      progress: 0,
      isPurchased: false,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: Flutter Basics',
          subtitle: 'Widgets and state management',
        ),
        const LessonItem(
          title: 'Chapter 2: Navigation',
          subtitle: 'Routing and navigation patterns',
        ),
        const LessonItem(
          title: 'Chapter 3: Backend Integration',
          subtitle: 'APIs and databases',
        ),
        const LessonItem(
          title: 'Chapter 4: Deployment',
          subtitle: 'App store publishing',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'App Project',
          passingMarks: '75%',
          deadline: 'Jun 10, 2026',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'Jun 15, 2026',
        description: 'Build and deploy a complete mobile app',
      ),
    ),
    CatalogCourse(
      id: 6,
      title: 'Digital Marketing Mastery',
      instructor: 'James Taylor',
      description:
          'Complete guide to digital marketing strategies including SEO, social media, and content marketing.',
      price: 69.99,
      progress: 1.0,
      isPurchased: true,
      lessons: [
        const LessonItem(
          title: 'Chapter 1: SEO Fundamentals',
          subtitle: 'Search engine optimization basics',
        ),
        const LessonItem(
          title: 'Chapter 2: Social Media',
          subtitle: 'Strategy and content creation',
        ),
        const LessonItem(
          title: 'Chapter 3: Email Marketing',
          subtitle: 'Campaigns and automation',
        ),
        const LessonItem(
          title: 'Chapter 4: Analytics',
          subtitle: 'Measuring and optimizing performance',
        ),
      ],
      assessments: [
        const AssessmentItem(
          title: 'Marketing Plan',
          passingMarks: '70%',
          deadline: 'Feb 20, 2026',
        ),
      ],
      finalExam: const FinalExamItem(
        examDate: 'Feb 25, 2026',
        description: 'Create a full digital marketing campaign',
      ),
    ),
  ];
}
