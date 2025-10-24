import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/progress_provider.dart';
import '../providers/course_provider.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/achievement_card.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
      ),
      body: Consumer2<ProgressProvider, CourseProvider>(
        builder: (context, progressProvider, courseProvider, child) {
          final userProgress = progressProvider.userProgress;
          
          if (userProgress == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await progressProvider.initializeProgress();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // User Info Card
                      _buildUserInfoCard(context),
                      
                      const SizedBox(height: 24),
                      
                      // Progress Summary
ProgressSummaryCard(
totalCourses: courseProvider.allCourses.length,
  completedCourses: progressProvider.getCompletedCourses().length,
  inProgressCourses: progressProvider.getInProgressCourses().length,
  totalLearningTime: userProgress.totalStudyTimeMinutes,
),
                      
                      const SizedBox(height: 24),
                      
                      // Achievements
                      _buildAchievementsSection(context, userProgress),
                      
                      const SizedBox(height: 24),
                      
                      // Learning Stats
                      _buildLearningStats(context, userProgress),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      _buildRecentActivity(context, progressProvider, courseProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Completed Courses
                      _buildCompletedCourses(context, progressProvider, courseProvider),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Enthusiast',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Foundation Hub Member',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, userProgress) {
    final achievements = _getAchievements(userProgress);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(
                  right: index == achievements.length - 1 ? 0 : 12,
                ),
                child: AchievementCard(
                  title: achievement['title'],
                  description: achievement['description'],
                  icon: achievement['icon'],
                  isUnlocked: achievement['isUnlocked'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStats(BuildContext context, userProgress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.schedule,
                    'Study Time',
                    '${(userProgress.totalStudyTimeMinutes / 60).toStringAsFixed(1)}h',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.trending_up,
                    'Streak',
                    '7 days', // This would be calculated based on daily activity
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.star,
                    'Level',
                    _calculateLevel(userProgress.totalLessonsCompleted).toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.emoji_events,
                    'Rank',
                    _calculateRank(userProgress.totalCoursesCompleted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, ProgressProvider progressProvider, CourseProvider courseProvider) {
    final inProgressCourses = progressProvider.getInProgressCourses();
    
    if (inProgressCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Continue Learning',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to courses screen
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: inProgressCourses.length,
            itemBuilder: (context, index) {
              final courseId = inProgressCourses[index];
              final course = courseProvider.getCourseById(courseId);
              final progress = progressProvider.getCourseProgress(courseId);
              
              if (course == null) return const SizedBox.shrink();
              
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index == inProgressCourses.length - 1 ? 0 : 12,
                ),
                child: CourseCard(
                  course: course,
                  progress: progress,
                  isCompact: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCourses(BuildContext context, ProgressProvider progressProvider, CourseProvider courseProvider) {
    final completedCourses = progressProvider.getCompletedCourses();
    
    if (completedCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Courses (${completedCourses.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: completedCourses.length,
          itemBuilder: (context, index) {
            final courseId = completedCourses[index];
            final course = courseProvider.getCourseById(courseId);
            final progress = progressProvider.getCourseProgress(courseId);
            
            if (course == null) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CourseCard(
                course: course,
                progress: progress,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getAchievements(userProgress) {
    return [
      {
        'title': 'First Steps',
        'description': 'Complete your first lesson',
        'icon': Icons.play_arrow,
        'isUnlocked': userProgress.totalLessonsCompleted >= 1,
      },
      {
        'title': 'Course Crusher',
        'description': 'Complete your first course',
        'icon': Icons.school,
        'isUnlocked': userProgress.totalCoursesCompleted >= 1,
      },
      {
        'title': 'AI Explorer',
        'description': 'Start 5 different courses',
        'icon': Icons.explore,
        'isUnlocked': userProgress.totalCoursesStarted >= 5,
      },
      {
        'title': 'Dedicated Learner',
        'description': 'Study for 10 hours total',
        'icon': Icons.schedule,
        'isUnlocked': userProgress.totalStudyTimeMinutes >= 600,
      },
      {
        'title': 'AI Master',
        'description': 'Complete 10 courses',
        'icon': Icons.emoji_events,
        'isUnlocked': userProgress.totalCoursesCompleted >= 10,
      },
    ];
  }

  int _calculateLevel(int lessonsCompleted) {
    return (lessonsCompleted / 10).floor() + 1;
  }

  String _calculateRank(int coursesCompleted) {
    if (coursesCompleted >= 20) return 'Expert';
    if (coursesCompleted >= 10) return 'Advanced';
    if (coursesCompleted >= 5) return 'Intermediate';
    if (coursesCompleted >= 1) return 'Beginner';
    return 'Newcomer';
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SettingsBottomSheet(),
    );
  }
}

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Theme Setting
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Light'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implement theme selection
            },
          ),
          
          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage your notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implement notification settings
            },
          ),
          
          // Reset Progress
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset All Progress'),
            subtitle: const Text('Clear all learning progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showResetDialog(context),
          ),
          
          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Foundation Hub v1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show about dialog
            },
          ),
          
          const SizedBox(height: 24),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress'),
        content: const Text(
          'Are you sure you want to reset all your learning progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProgressProvider>(context, listen: false).resetAllProgress();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All progress has been reset'),
                ),
              );
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
}

