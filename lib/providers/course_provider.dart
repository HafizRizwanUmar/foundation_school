import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/course_model.dart';

class CourseProvider with ChangeNotifier {
  List<CourseCategory> _categories = [];
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CourseCategory> get categories => _categories;
  List<Course> get allCourses => _allCourses;
  List<Course> get filteredCourses => _filteredCourses;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize and load course data
  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load course data from JSON file
      final String jsonString = await rootBundle.loadString("assets/data/courses_data.json");
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Load detailed lesson data
      final String detailedLessonsString = await rootBundle.loadString("assets/data/detailed_lessons.json");
      final Map<String, dynamic> detailedLessonsData = json.decode(detailedLessonsString);
      
      // Parse categories and courses with new simplified structure
      _categories = [];
      _allCourses = [];
      
      final categoriesData = jsonData["categories"] as List;

      for (var categoryData in categoriesData) {
        final categoryName = categoryData["category"] as String;
        final categoryId = categoryName.toLowerCase().replaceAll(" ", "_").replaceAll("&", "and");
        
        // Create courses for this category
        List<Course> categoryCourses = [];
        final coursesData = categoryData["courses"] as List;
        
        for (var courseData in coursesData) {
          final courseId = courseData["id"];
          List<Lesson> lessons = [];
          if (detailedLessonsData["courses"].containsKey(courseId)) {
            lessons = (detailedLessonsData["courses"][courseId]["lessons"] as List)
                .map((lesson) => Lesson.fromJson(lesson))
                .toList();
          }

          final course = Course(
            id: courseId,
            title: courseData["title"],
            description: "Master ${courseData["title"]} with comprehensive lessons and practical examples.",
            category: categoryId,
            imageUrl: "assets/images/${courseData["image"]}",
            iconUrl: "assets/icons/${courseData["id"]}.png",
            lessons: lessons,
            estimatedDuration: 120, // Default 2 hours
            difficulty: "Beginner",
            tags: [categoryName.toLowerCase(), "ai", "productivity"],
            aiToolUrl: _getToolUrl(courseId),
            aiToolDescription: "AI-powered tool for enhanced productivity and creativity",
          );
          
          categoryCourses.add(course);
          _allCourses.add(course);
        }
        
        // Create category
        final category = CourseCategory(
          id: categoryId,
          name: categoryName,
          description: "Master the most powerful $categoryName tools",
          iconUrl: "assets/icons/${categoryId}.png",
          courses: categoryCourses,
        );
        
        _categories.add(category);
      }
      
      // Initialize filtered courses with all courses
      _filteredCourses = List.from(_allCourses);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Failed to load courses: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get tool URL based on course ID
  String _getToolUrl(String courseId) {
    final urlMap = {
      "chatgpt": "https://chat.openai.com",
      "grok": "https://grok.x.ai",
      "claude": "https://claude.ai",
      "gemini": "https://gemini.google.com",
      "synthesia": "https://www.synthesia.io",
      "google_veo": "https://ai.google/discover/veo",
      "opusclip": "https://www.opus.pro",
      "midjourney": "https://www.midjourney.com",
      "fathom": "https://fathom.video",
      "nyota": "https://www.nyota.ai",
      "n8n": "https://n8n.io",
      "manus": "https://www.manus.chat",
      "perplexity": "https://www.perplexity.ai",
      "elevenlabs": "https://elevenlabs.io",
      "canva_magic_studio": "https://www.canva.com",
    };
    
    return urlMap[courseId] ?? "https://example.com";
  }

  // Search courses
  void searchCourses(String query) {
    _searchQuery = query.toLowerCase();
    _filterCourses();
  }

  // Filter by category
  void filterByCategory(String categoryId) {
    _selectedCategory = categoryId;
    _filterCourses();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = "";
    _selectedCategory = "";
    _filteredCourses = List.from(_allCourses);
    notifyListeners();
  }

  // Apply filters
  void _filterCourses() {
    _filteredCourses = _allCourses.where((course) {
      bool matchesSearch = _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery) ||
          course.description.toLowerCase().contains(_searchQuery) ||
          course.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));

      bool matchesCategory = _selectedCategory.isEmpty ||
          course.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    notifyListeners();
  }

  // Get course by ID
  Course? getCourseById(String courseId) {
    try {
      return _allCourses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get courses by category
  List<Course> getCoursesByCategory(String categoryId) {
    return _allCourses.where((course) => course.category == categoryId).toList();
  }

  // Get category by ID
  CourseCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get featured courses (first 6 courses)
  List<Course> getFeaturedCourses() {
    return _allCourses.take(6).toList();
  }

  // Get popular courses (can be based on completion rates, ratings, etc.)
  List<Course> getPopularCourses() {
    // For now, return courses sorted by estimated duration (shorter courses might be more popular)
    var sortedCourses = List<Course>.from(_allCourses);
    sortedCourses.sort((a, b) => a.estimatedDuration.compareTo(b.estimatedDuration));
    return sortedCourses.take(8).toList();
  }

  // Get recent courses (last added)
  List<Course> getRecentCourses() {
    // For now, return the last 5 courses
    return _allCourses.reversed.take(5).toList();
  }

  // Search suggestions
  List<String> getSearchSuggestions(String query) {
    if (query.isEmpty) return [];
    
    Set<String> suggestions = {};
    
    // Add matching course titles
    for (var course in _allCourses) {
      if (course.title.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(course.title);
      }
    }
    
    // Add matching tags
    for (var course in _allCourses) {
      for (var tag in course.tags) {
        if (tag.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(tag);
        }
      }
    }
    
    return suggestions.take(5).toList();
  }
}