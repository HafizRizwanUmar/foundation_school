import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress_model.dart';
import '../models/course_model.dart';

class ProgressProvider with ChangeNotifier {
  UserProgress? _userProgress;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProgress? get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize user progress
  Future<void> initializeProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadProgressFromStorage();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load progress: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load progress from local storage
  Future<void> _loadProgressFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('user_progress');
    
    if (progressJson != null) {
      final progressData = json.decode(progressJson);
      _userProgress = UserProgress.fromJson(progressData);
    } else {
      // Create new user progress
      _userProgress = UserProgress(
        userId: 'local_user',
        courseProgress: {},
        lastUpdated: DateTime.now(),
        totalCoursesStarted: 0,
        totalCoursesCompleted: 0,
        totalLessonsCompleted: 0,
        totalStudyTimeMinutes: 0,
      );
      await _saveProgressToStorage();
    }
  }

  // Save progress to local storage
  Future<void> _saveProgressToStorage() async {
    if (_userProgress == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final progressJson = json.encode(_userProgress!.toJson());
    await prefs.setString('user_progress', progressJson);
  }

  // Start a course
  Future<void> startCourse(String courseId) async {
    if (_userProgress == null) return;

    final now = DateTime.now();
    final existingProgress = _userProgress!.courseProgress[courseId];

    if (existingProgress == null) {
      // Create new course progress
      final courseProgress = CourseProgress(
        courseId: courseId,
        isStarted: true,
        isCompleted: false,
        startedAt: now,
        lastAccessedAt: now,
        lessonProgress: {},
        currentLessonIndex: 0,
        progressPercentage: 0.0,
        studyTimeMinutes: 0,
      );

      final updatedCourseProgress = Map<String, CourseProgress>.from(_userProgress!.courseProgress);
      updatedCourseProgress[courseId] = courseProgress;

      _userProgress = _userProgress!.copyWith(
        courseProgress: updatedCourseProgress,
        totalCoursesStarted: _userProgress!.totalCoursesStarted + 1,
        lastUpdated: now,
      );
    } else if (!existingProgress.isStarted) {
      // Update existing progress to started
      final updatedCourseProgress = Map<String, CourseProgress>.from(_userProgress!.courseProgress);
      updatedCourseProgress[courseId] = existingProgress.copyWith(
        isStarted: true,
        startedAt: now,
        lastAccessedAt: now,
      );

      _userProgress = _userProgress!.copyWith(
        courseProgress: updatedCourseProgress,
        totalCoursesStarted: _userProgress!.totalCoursesStarted + 1,
        lastUpdated: now,
      );
    }

    await _saveProgressToStorage();
    notifyListeners();
  }

  // Complete a lesson
  Future<void> completeLesson(String courseId, String lessonId, int studyTimeMinutes, {Course? course}) async {
    if (_userProgress == null) return;

    final now = DateTime.now();
    final courseProgress = _userProgress!.courseProgress[courseId];
    
    if (courseProgress == null) {
      await startCourse(courseId);
      return completeLesson(courseId, lessonId, studyTimeMinutes, course: course);
    }

    // Update lesson progress
    final updatedLessonProgress = Map<String, LessonProgress>.from(courseProgress.lessonProgress);
    final existingLessonProgress = updatedLessonProgress[lessonId];

    if (existingLessonProgress == null) {
      updatedLessonProgress[lessonId] = LessonProgress(
        lessonId: lessonId,
        isCompleted: true,
        isStarted: true,
        startedAt: now,
        completedAt: now,
        lastAccessedAt: now,
        watchTimeMinutes: studyTimeMinutes,
        progressPercentage: 100.0,
      );
    } else if (!existingLessonProgress.isCompleted) {
      updatedLessonProgress[lessonId] = existingLessonProgress.copyWith(
        isCompleted: true,
        completedAt: now,
        lastAccessedAt: now,
        watchTimeMinutes: existingLessonProgress.watchTimeMinutes + studyTimeMinutes,
        progressPercentage: 100.0,
      );
    }

    // Calculate course progress based on actual course lessons if provided
    double progressPercentage;
    bool isCompleted;
    
    if (course != null) {
      final totalLessons = course.lessons.length;
      final completedLessons = updatedLessonProgress.values.where((lesson) => lesson.isCompleted).length;
      progressPercentage = totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;
      isCompleted = completedLessons >= totalLessons;
    } else {
      // Fallback to old calculation
      final totalLessons = updatedLessonProgress.length;
      final completedLessons = updatedLessonProgress.values.where((lesson) => lesson.isCompleted).length;
      progressPercentage = totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;
      isCompleted = progressPercentage >= 100.0;
    }

    // Update course progress
    final updatedCourseProgress = Map<String, CourseProgress>.from(_userProgress!.courseProgress);
    updatedCourseProgress[courseId] = courseProgress.copyWith(
      lessonProgress: updatedLessonProgress,
      lastAccessedAt: now,
      progressPercentage: progressPercentage,
      isCompleted: isCompleted,
      completedAt: isCompleted ? now : null,
      studyTimeMinutes: courseProgress.studyTimeMinutes + studyTimeMinutes,
    );

    // Update user progress
    final wasCompleted = courseProgress.isCompleted;
    _userProgress = _userProgress!.copyWith(
      courseProgress: updatedCourseProgress,
      totalLessonsCompleted: _userProgress!.totalLessonsCompleted + 1,
      totalCoursesCompleted: isCompleted && !wasCompleted 
          ? _userProgress!.totalCoursesCompleted + 1 
          : _userProgress!.totalCoursesCompleted,
      totalStudyTimeMinutes: _userProgress!.totalStudyTimeMinutes + studyTimeMinutes,
      lastUpdated: now,
    );

    await _saveProgressToStorage();
    notifyListeners();
  }

  // Update lesson progress (for tracking reading/watching time)
  Future<void> updateLessonProgress(String courseId, String lessonId, double progressPercentage, int studyTimeMinutes) async {
    if (_userProgress == null) return;

    final now = DateTime.now();
    final courseProgress = _userProgress!.courseProgress[courseId];
    
    if (courseProgress == null) {
      await startCourse(courseId);
      return updateLessonProgress(courseId, lessonId, progressPercentage, studyTimeMinutes);
    }

    // Update lesson progress
    final updatedLessonProgress = Map<String, LessonProgress>.from(courseProgress.lessonProgress);
    final existingLessonProgress = updatedLessonProgress[lessonId];

    if (existingLessonProgress == null) {
      updatedLessonProgress[lessonId] = LessonProgress(
        lessonId: lessonId,
        isCompleted: progressPercentage >= 100.0,
        isStarted: true,
        startedAt: now,
        completedAt: progressPercentage >= 100.0 ? now : null,
        lastAccessedAt: now,
        watchTimeMinutes: studyTimeMinutes,
        progressPercentage: progressPercentage,
      );
    } else {
      updatedLessonProgress[lessonId] = existingLessonProgress.copyWith(
        isCompleted: progressPercentage >= 100.0,
        completedAt: progressPercentage >= 100.0 ? now : existingLessonProgress.completedAt,
        lastAccessedAt: now,
        watchTimeMinutes: existingLessonProgress.watchTimeMinutes + studyTimeMinutes,
        progressPercentage: progressPercentage,
      );
    }

    // Update course progress
    final updatedCourseProgress = Map<String, CourseProgress>.from(_userProgress!.courseProgress);
    updatedCourseProgress[courseId] = courseProgress.copyWith(
      lessonProgress: updatedLessonProgress,
      lastAccessedAt: now,
      studyTimeMinutes: courseProgress.studyTimeMinutes + studyTimeMinutes,
    );

    // Update user progress
    _userProgress = _userProgress!.copyWith(
      courseProgress: updatedCourseProgress,
      totalStudyTimeMinutes: _userProgress!.totalStudyTimeMinutes + studyTimeMinutes,
      lastUpdated: now,
    );

    await _saveProgressToStorage();
    notifyListeners();
  }

  // Reset course progress
  Future<void> resetCourse(String courseId) async {
    if (_userProgress == null) return;

    final courseProgress = _userProgress!.courseProgress[courseId];
    if (courseProgress == null) return;

    final updatedCourseProgress = Map<String, CourseProgress>.from(_userProgress!.courseProgress);
    updatedCourseProgress.remove(courseId);

    _userProgress = _userProgress!.copyWith(
      courseProgress: updatedCourseProgress,
      totalCoursesStarted: _userProgress!.totalCoursesStarted - 1,
      totalCoursesCompleted: courseProgress.isCompleted 
          ? _userProgress!.totalCoursesCompleted - 1 
          : _userProgress!.totalCoursesCompleted,
      totalLessonsCompleted: _userProgress!.totalLessonsCompleted - 
          courseProgress.lessonProgress.values.where((lesson) => lesson.isCompleted).length,
      totalStudyTimeMinutes: _userProgress!.totalStudyTimeMinutes - courseProgress.studyTimeMinutes,
      lastUpdated: DateTime.now(),
    );

    await _saveProgressToStorage();
    notifyListeners();
  }

  // Reset all progress
  Future<void> resetAllProgress() async {
    _userProgress = UserProgress(
      userId: 'local_user',
      courseProgress: {},
      lastUpdated: DateTime.now(),
      totalCoursesStarted: 0,
      totalCoursesCompleted: 0,
      totalLessonsCompleted: 0,
      totalStudyTimeMinutes: 0,
    );

    await _saveProgressToStorage();
    notifyListeners();
  }

  // Get course progress
  CourseProgress? getCourseProgress(String courseId) {
    return _userProgress?.courseProgress[courseId];
  }

  // Get lesson progress
  LessonProgress? getLessonProgress(String courseId, String lessonId) {
    final courseProgress = getCourseProgress(courseId);
    return courseProgress?.lessonProgress[lessonId];
  }

  // Check if course is started
  bool isCourseStarted(String courseId) {
    final progress = getCourseProgress(courseId);
    return progress?.isStarted ?? false;
  }

  // Check if course is completed
  bool isCourseCompleted(String courseId) {
    final progress = getCourseProgress(courseId);
    return progress?.isCompleted ?? false;
  }

  // Check if lesson is completed
  bool isLessonCompleted(String courseId, String lessonId) {
    final progress = getLessonProgress(courseId, lessonId);
    return progress?.isCompleted ?? false;
  }

  // Get course progress percentage
  double getCourseProgressPercentage(String courseId, {Course? course}) {
    final progress = getCourseProgress(courseId);
    if (progress == null) return 0.0;
    
    // If course object is provided, calculate based on actual lesson count
    if (course != null) {
      final totalLessons = course.lessons.length;
      final completedLessons = progress.lessonProgress.values
          .where((lesson) => lesson.isCompleted)
          .length;
      return totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;
    }
    
    // Fallback to stored progress percentage
    return progress.progressPercentage;
  }

  // Get lesson progress percentage
  double getLessonProgressPercentage(String courseId, String lessonId) {
    final progress = getLessonProgress(courseId, lessonId);
    return progress?.progressPercentage ?? 0.0;
  }

  // Get completed courses
  List<String> getCompletedCourses() {
    if (_userProgress == null) return [];
    return _userProgress!.courseProgress.entries
        .where((entry) => entry.value.isCompleted)
        .map((entry) => entry.key)
        .toList();
  }

  // Get in-progress courses
  List<String> getInProgressCourses() {
    if (_userProgress == null) return [];
    return _userProgress!.courseProgress.entries
        .where((entry) => entry.value.isStarted && !entry.value.isCompleted)
        .map((entry) => entry.key)
        .toList();
  }

  // Additional helper methods for UI
  int get completedCoursesCount => getCompletedCourses().length;
  int get inProgressCoursesCount => getInProgressCourses().length;
  int get totalLearningTime => _userProgress?.totalStudyTimeMinutes ?? 0;

  // Get recently accessed courses
  List<String> getRecentlyAccessedCourses({int limit = 5}) {
    if (_userProgress == null) return [];
    
    final sortedEntries = _userProgress!.courseProgress.entries.toList()
      ..sort((a, b) => b.value.lastAccessedAt.compareTo(a.value.lastAccessedAt));
    
    return sortedEntries
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  // Get learning streak (consecutive days with activity)
  int getLearningStreak() {
    if (_userProgress == null) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    
    // Get all activity dates
    final activityDates = <DateTime>{};
    for (final courseProgress in _userProgress!.courseProgress.values) {
      if (courseProgress.lastAccessedAt != null) {
        final date = courseProgress.lastAccessedAt;
        activityDates.add(DateTime(date.year, date.month, date.day));
      }
    }
    
    // Calculate streak
    DateTime checkDate = today;
    while (activityDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  // Get weekly learning time
  int getWeeklyLearningTime() {
    if (_userProgress == null) return 0;
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int weeklyTime = 0;
    
    for (final courseProgress in _userProgress!.courseProgress.values) {
      if (courseProgress.lastAccessedAt.isAfter(weekAgo)) {
        weeklyTime += courseProgress.studyTimeMinutes;
      }
    }
    
    return weeklyTime;
  }

  // Get course completion rate
  double getCourseCompletionRate() {
    if (_userProgress == null || _userProgress!.totalCoursesStarted == 0) return 0.0;
    return (_userProgress!.totalCoursesCompleted / _userProgress!.totalCoursesStarted) * 100;
  }

  // Get average session time
  double getAverageSessionTime() {
    if (_userProgress == null || _userProgress!.totalLessonsCompleted == 0) return 0.0;
    return _userProgress!.totalStudyTimeMinutes / _userProgress!.totalLessonsCompleted;
  }

  // Export progress data
  Map<String, dynamic> exportProgressData() {
    return _userProgress?.toJson() ?? {};
  }

  // Import progress data
  Future<void> importProgressData(Map<String, dynamic> data) async {
    try {
      _userProgress = UserProgress.fromJson(data);
      await _saveProgressToStorage();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to import progress data: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sync progress (placeholder for future cloud sync)
  Future<void> syncProgress() async {
    // TODO: Implement cloud sync functionality
    // For now, just save to local storage
    await _saveProgressToStorage();
  }
}

