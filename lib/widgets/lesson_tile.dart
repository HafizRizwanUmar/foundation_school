import 'package:flutter/material.dart';
import '../models/course_model.dart';
import 'progress_indicator_widget.dart';

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final double progress;
  final VoidCallback? onTap;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.isCompleted,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Lesson Number/Status
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : progress > 0
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          '${lesson.order}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progress > 0
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Lesson Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.duration} min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _getLessonTypeIcon(lesson.type),
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.type,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    
                    // Progress Bar
                    if (progress > 0 && !isCompleted) ...[
                      const SizedBox(height: 8),
                      ProgressIndicatorWidget(
                        progress: progress / 100,
                        height: 4,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Icon
              Icon(
                isCompleted
                    ? Icons.replay
                    : progress > 0
                        ? Icons.play_circle
                        : Icons.play_circle_outline,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : progress > 0
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLessonTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'interactive':
        return Icons.touch_app;
      case 'text':
      default:
        return Icons.article;
    }
  }
}

