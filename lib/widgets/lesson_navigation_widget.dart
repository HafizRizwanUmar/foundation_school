import 'package:flutter/material.dart';
import '../models/course_model.dart';

class LessonNavigationWidget extends StatelessWidget {
  final Course course;
  final int currentLessonIndex;
  final VoidCallback? onPreviousLesson;
  final VoidCallback? onNextLesson;

  const LessonNavigationWidget({
    super.key,
    required this.course,
    required this.currentLessonIndex,
    this.onPreviousLesson,
    this.onNextLesson,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrevious = currentLessonIndex > 0;
    final hasNext = currentLessonIndex < course.lessons.length - 1;

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
            // Previous Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasPrevious ? onPreviousLesson : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Lesson Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentLessonIndex + 1} / ${course.lessons.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasNext ? onNextLesson : null,
                icon: const Icon(Icons.arrow_forward),
                label: Text(hasNext ? 'Next' : 'Complete'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

