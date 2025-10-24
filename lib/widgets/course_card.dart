import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/user_progress_model.dart';
import 'progress_indicator_widget.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final CourseProgress? progress;
  final VoidCallback? onTap;
  final bool isCompact;

  const CourseCard({
    super.key,
    required this.course,
    this.progress,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isStarted = progress?.isStarted ?? false;
    final isCompleted = progress?.isCompleted ?? false;
    final progressPercentage = progress?.progressPercentage ?? 0.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isCompact ? _buildCompactLayout(context, isStarted, isCompleted, progressPercentage)
                            : _buildFullLayout(context, isStarted, isCompleted, progressPercentage),
          ),
        ),
      ),
    );
  }

  Widget _buildFullLayout(BuildContext context, bool isStarted, bool isCompleted, double progressPercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image and Status
        Stack(
          children: [
            // Course Image
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  course.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Status Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withOpacity(0.9)
                      : isStarted 
                          ? Colors.orange.withOpacity(0.9)
                          : Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted 
                          ? Icons.check_circle
                          : isStarted 
                              ? Icons.play_circle_filled
                              : Icons.play_arrow,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted 
                          ? 'Completed'
                          : isStarted 
                              ? 'In Progress'
                              : 'Start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Course Title
        Text(
          course.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Course Description
        Text(
          course.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 16),
        
        // Course Details
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDetailChip(
              context,
              Icons.schedule_rounded,
              '${course.estimatedDuration} min',
              Colors.blue,
            ),
            _buildDetailChip(
              context,
              Icons.signal_cellular_alt_rounded,
              course.difficulty,
              Colors.purple,
            ),
            _buildDetailChip(
              context,
              Icons.play_lesson_rounded,
              '${course.lessons.length} lessons',
              Colors.green,
            ),
          ],
        ),
        
        // Progress Bar
        if (isStarted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressIndicatorWidget(
                  progress: progressPercentage / 100,
                  height: 8,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, bool isStarted, bool isCompleted, double progressPercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              course.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Course Title
        Text(
          course.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Course Details
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '${course.estimatedDuration} min',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.play_lesson_rounded,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '${course.lessons.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Status or Progress
        if (isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (isStarted)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressIndicatorWidget(
                progress: progressPercentage / 100,
                height: 6,
              ),
              const SizedBox(height: 6),
              Text(
                '${progressPercentage.toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Start Learning',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

