import 'package:flutter/material.dart';
import '../models/course_model.dart';

class CategoryCard extends StatelessWidget {
  final CourseCategory category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(category.id),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Category Name
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Course Count
              Text(
                '${category.courses.length} courses',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'ai_assistants':
        return Icons.smart_toy;
      case 'video_generation':
        return Icons.videocam;
      case 'image_generation':
        return Icons.image;
      case 'meeting_assistants':
        return Icons.meeting_room;
      case 'automation':
        return Icons.auto_awesome;
      case 'research':
        return Icons.search;
      case 'writing':
        return Icons.edit;
      case 'search_engines':
        return Icons.travel_explore;
      case 'graphic_design':
        return Icons.design_services;
      case 'app_builders':
        return Icons.build;
      case 'knowledge_management':
        return Icons.library_books;
      case 'email':
        return Icons.email;
      case 'scheduling':
        return Icons.schedule;
      case 'presentations':
        return Icons.slideshow;
      case 'resume_builders':
        return Icons.description;
      case 'voice_generation':
        return Icons.record_voice_over;
      case 'music_generation':
        return Icons.music_note;
      case 'marketing':
        return Icons.campaign;
      case 'advertising':
        return Icons.ads_click;
      case 'seo':
        return Icons.trending_up;
      case 'productivity':
        return Icons.ads_click;
      case 'video_editing':
        return Icons.video_library;
      case 'ai_chatbots':
        return Icons.chat;
      default:
        return Icons.category;
    }
  }
}

