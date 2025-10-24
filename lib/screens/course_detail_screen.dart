import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';
import '../providers/progress_provider.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/banner_ad_widget.dart';
import 'lesson_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          final courseProgress = progressProvider.getCourseProgress(widget.course.id);
          final isStarted = progressProvider.isCourseStarted(widget.course.id);
          final isCompleted = progressProvider.isCourseCompleted(widget.course.id);
          final progressPercentage = progressProvider.getCourseProgressPercentage(widget.course.id, course: widget.course);

          return CustomScrollView(
            slivers: [
              // App Bar with Course Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Course Image
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Course Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Course Title and Info
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    context,
                                    Icons.schedule,
                                    '${widget.course.estimatedDuration} min',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    context,
                                    Icons.signal_cellular_alt,
                                    widget.course.difficulty,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    context,
                                    Icons.play_lesson,
                                    '${widget.course.lessons.length} lessons',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress Card
                    if (isStarted)
                      AnimationConfiguration.staggeredList(
                        position: 1,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isCompleted ? 'Course Completed!' : 'Your Progress',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isCompleted)
                                          Icon(
                                            Icons.check_circle,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ProgressIndicatorWidget(
                                      progress: progressPercentage / 100,
                                      height: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${progressPercentage.toInt()}% Complete',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Course Description
                    AnimationConfiguration.staggeredList(
                      position: 2,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About this course',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.course.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: _isExpanded ? null : 3,
                                overflow: _isExpanded ? null : TextOverflow.ellipsis,
                              ),
                              if (widget.course.description.length > 150)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: Text(_isExpanded ? 'Show less' : 'Show more'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AI Tool Info
                    AnimationConfiguration.staggeredList(
                      position: 3,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.link,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Tool',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.course.aiToolDescription,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _launchUrl(widget.course.aiToolUrl),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Visit Tool'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tags
                    if (widget.course.tags.isNotEmpty)
                      AnimationConfiguration.staggeredList(
                        position: 4,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tags',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.course.tags.map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Lessons Section
                    AnimationConfiguration.staggeredList(
                      position: 5,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Text(
                            'Lessons (${widget.course.lessons.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lessons List
                    AnimationLimiter(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.course.lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = widget.course.lessons[index];
                          final lessonProgress = progressProvider.getLessonProgress(
                            widget.course.id,
                            lesson.id,
                          );
                          final isLessonCompleted = progressProvider.isLessonCompleted(
                            widget.course.id,
                            lesson.id,
                          );

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: LessonTile(
                                  lesson: lesson,
                                  isCompleted: isLessonCompleted,
                                  progress: lessonProgress?.progressPercentage ?? 0.0,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LessonScreen(
                                          course: widget.course,
                                          lesson: lesson,
                                          lessonIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          final isStarted = progressProvider.isCourseStarted(widget.course.id);
          final isCompleted = progressProvider.isCourseCompleted(widget.course.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (isStarted && !isCompleted)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showResetDialog(context),
                        child: const Text('Reset Progress'),
                      ),
                    ),
                  if (isStarted && !isCompleted) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _startOrContinueCourse(context),
                      child: Text(
                        isCompleted
                            ? 'Review Course'
                            : isStarted
                                ? 'Continue Learning'
                                : 'Start Course',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _startOrContinueCourse(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    
    if (!progressProvider.isCourseStarted(widget.course.id)) {
      progressProvider.startCourse(widget.course.id);
    }

    // Navigate to first incomplete lesson or first lesson
    final firstIncompleteLesson = widget.course.lessons.firstWhere(
      (lesson) => !progressProvider.isLessonCompleted(widget.course.id, lesson.id),
      orElse: () => widget.course.lessons.first,
    );

    final lessonIndex = widget.course.lessons.indexOf(firstIncompleteLesson);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          course: widget.course,
          lesson: firstIncompleteLesson,
          lessonIndex: lessonIndex,
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset your progress for this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProgressProvider>(context, listen: false)
                  .resetCourse(widget.course.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

