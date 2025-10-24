class UserProgress {
  final String userId;
  final Map<String, CourseProgress> courseProgress;
  final DateTime lastUpdated;
  final int totalCoursesStarted;
  final int totalCoursesCompleted;
  final int totalLessonsCompleted;
  final int totalStudyTimeMinutes;

  UserProgress({
    required this.userId,
    required this.courseProgress,
    required this.lastUpdated,
    required this.totalCoursesStarted,
    required this.totalCoursesCompleted,
    required this.totalLessonsCompleted,
    required this.totalStudyTimeMinutes,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    Map<String, CourseProgress> courseProgressMap = {};
    if (json['courseProgress'] != null) {
      (json['courseProgress'] as Map<String, dynamic>).forEach((key, value) {
        courseProgressMap[key] = CourseProgress.fromJson(value);
      });
    }

    return UserProgress(
      userId: json['userId'],
      courseProgress: courseProgressMap,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      totalCoursesStarted: json['totalCoursesStarted'] ?? 0,
      totalCoursesCompleted: json['totalCoursesCompleted'] ?? 0,
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalStudyTimeMinutes: json['totalStudyTimeMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> courseProgressMap = {};
    courseProgress.forEach((key, value) {
      courseProgressMap[key] = value.toJson();
    });

    return {
      'userId': userId,
      'courseProgress': courseProgressMap,
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalCoursesStarted': totalCoursesStarted,
      'totalCoursesCompleted': totalCoursesCompleted,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
    };
  }

  UserProgress copyWith({
    String? userId,
    Map<String, CourseProgress>? courseProgress,
    DateTime? lastUpdated,
    int? totalCoursesStarted,
    int? totalCoursesCompleted,
    int? totalLessonsCompleted,
    int? totalStudyTimeMinutes,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      courseProgress: courseProgress ?? this.courseProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalCoursesStarted: totalCoursesStarted ?? this.totalCoursesStarted,
      totalCoursesCompleted: totalCoursesCompleted ?? this.totalCoursesCompleted,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
    );
  }
}

class CourseProgress {
  final String courseId;
  final bool isStarted;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  final Map<String, LessonProgress> lessonProgress;
  final int currentLessonIndex;
  final double progressPercentage;
  final int studyTimeMinutes;

  CourseProgress({
    required this.courseId,
    required this.isStarted,
    required this.isCompleted,
    this.startedAt,
    this.completedAt,
    required this.lastAccessedAt,
    required this.lessonProgress,
    required this.currentLessonIndex,
    required this.progressPercentage,
    required this.studyTimeMinutes,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    Map<String, LessonProgress> lessonProgressMap = {};
    if (json['lessonProgress'] != null) {
      (json['lessonProgress'] as Map<String, dynamic>).forEach((key, value) {
        lessonProgressMap[key] = LessonProgress.fromJson(value);
      });
    }

    return CourseProgress(
      courseId: json['courseId'],
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      lessonProgress: lessonProgressMap,
      currentLessonIndex: json['currentLessonIndex'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      studyTimeMinutes: json['studyTimeMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> lessonProgressMap = {};
    lessonProgress.forEach((key, value) {
      lessonProgressMap[key] = value.toJson();
    });

    return {
      'courseId': courseId,
      'isStarted': isStarted,
      'isCompleted': isCompleted,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'lessonProgress': lessonProgressMap,
      'currentLessonIndex': currentLessonIndex,
      'progressPercentage': progressPercentage,
      'studyTimeMinutes': studyTimeMinutes,
    };
  }

  CourseProgress copyWith({
    String? courseId,
    bool? isStarted,
    bool? isCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastAccessedAt,
    Map<String, LessonProgress>? lessonProgress,
    int? currentLessonIndex,
    double? progressPercentage,
    int? studyTimeMinutes,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      isStarted: isStarted ?? this.isStarted,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      studyTimeMinutes: studyTimeMinutes ?? this.studyTimeMinutes,
    );
  }
}

class LessonProgress {
  final String lessonId;
  final bool isCompleted;
  final bool isStarted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  final int watchTimeMinutes;
  final double progressPercentage;

  LessonProgress({
    required this.lessonId,
    required this.isCompleted,
    required this.isStarted,
    this.startedAt,
    this.completedAt,
    required this.lastAccessedAt,
    required this.watchTimeMinutes,
    required this.progressPercentage,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'],
      isCompleted: json['isCompleted'] ?? false,
      isStarted: json['isStarted'] ?? false,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      watchTimeMinutes: json['watchTimeMinutes'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'isCompleted': isCompleted,
      'isStarted': isStarted,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'watchTimeMinutes': watchTimeMinutes,
      'progressPercentage': progressPercentage,
    };
  }

  LessonProgress copyWith({
    String? lessonId,
    bool? isCompleted,
    bool? isStarted,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastAccessedAt,
    int? watchTimeMinutes,
    double? progressPercentage,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarted: isStarted ?? this.isStarted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      watchTimeMinutes: watchTimeMinutes ?? this.watchTimeMinutes,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

