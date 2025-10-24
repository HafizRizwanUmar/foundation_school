class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String iconUrl;
  final List<Lesson> lessons;
  final int estimatedDuration; // in minutes
  final String difficulty; // Beginner, Intermediate, Advanced
  final List<String> tags;
  final String aiToolUrl;
  final String aiToolDescription;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.iconUrl,
    required this.lessons,
    required this.estimatedDuration,
    required this.difficulty,
    required this.tags,
    required this.aiToolUrl,
    required this.aiToolDescription,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      iconUrl: json['iconUrl'],
      lessons: (json['lessons'] as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList(),
      estimatedDuration: json['estimatedDuration'],
      difficulty: json['difficulty'],
      tags: List<String>.from(json['tags']),
      aiToolUrl: json['aiToolUrl'],
      aiToolDescription: json['aiToolDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'difficulty': difficulty,
      'tags': tags,
      'aiToolUrl': aiToolUrl,
      'aiToolDescription': aiToolDescription,
    };
  }
}

class Lesson {
  final String id;
  final String title;
  final String content;
  final int duration; // in minutes
  final int order;
  final String type; // text, video, interactive
  final List<String> keyPoints;
  final String? audioUrl;
  final List<LessonResource> resources;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.duration,
    required this.order,
    required this.type,
    required this.keyPoints,
    this.audioUrl,
    required this.resources,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      duration: json['duration'],
      order: json['order'],
      type: json['type'],
      keyPoints: List<String>.from(json['keyPoints']),
      audioUrl: json['audioUrl'],
      resources: (json['resources'] as List)
          .map((resource) => LessonResource.fromJson(resource))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'duration': duration,
      'order': order,
      'type': type,
      'keyPoints': keyPoints,
      'audioUrl': audioUrl,
      'resources': resources.map((resource) => resource.toJson()).toList(),
    };
  }
}

class LessonResource {
  final String title;
  final String url;
  final String type; // link, download, video

  LessonResource({
    required this.title,
    required this.url,
    required this.type,
  });

  factory LessonResource.fromJson(Map<String, dynamic> json) {
    return LessonResource(
      title: json['title'],
      url: json['url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'type': type,
    };
  }
}

class CourseCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final List<Course> courses;

  CourseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.courses,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['iconUrl'],
      courses: (json['courses'] as List)
          .map((course) => Course.fromJson(course))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'courses': courses.map((course) => course.toJson()).toList(),
    };
  }
}

