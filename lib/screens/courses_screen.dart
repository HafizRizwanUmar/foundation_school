import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/course_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/course_card.dart';
import '../widgets/filter_chip_widget.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final String? initialCategory;
  
  const CoursesScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedDifficulty = '';
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<CourseProvider>(context, listen: false)
            .filterByCategory(_selectedCategory);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    Provider.of<CourseProvider>(context, listen: false).searchCourses(query);
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    Provider.of<CourseProvider>(context, listen: false).filterByCategory(category);
  }

  void _onDifficultyChanged(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    // Apply difficulty filter
    _applyFilters();
  }

  void _applyFilters() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    // First apply category filter
    courseProvider.filterByCategory(_selectedCategory);
    
    // Then apply difficulty filter if selected
    if (_selectedDifficulty.isNotEmpty) {
      // This would need to be implemented in the provider
      // For now, we'll filter locally
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = '';
      _selectedDifficulty = '';
      _searchController.clear();
    });
    Provider.of<CourseProvider>(context, listen: false).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Consumer2<CourseProvider, ProgressProvider>(
        builder: (context, courseProvider, progressProvider, child) {
          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Filter Chips
              if (_selectedCategory.isNotEmpty || _selectedDifficulty.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (_selectedCategory.isNotEmpty)
                        FilterChipWidget(
                          label: courseProvider.getCategoryById(_selectedCategory)?.name ?? _selectedCategory,
                          isSelected: true,
                          onTap: () => _onCategoryChanged(''),
                        ),
                      if (_selectedDifficulty.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChipWidget(
                            label: _selectedDifficulty,
                            isSelected: true,
                            onTap: () => _onDifficultyChanged(''),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),

              // Course Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${courseProvider.filteredCourses.length} courses found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Courses List
              Expanded(
                child: courseProvider.filteredCourses.isEmpty
                    ? _buildEmptyState(context)
                    : AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: courseProvider.filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = courseProvider.filteredCourses[index];
                            final progress = progressProvider.getCourseProgress(course.id);
                            
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: CourseCard(
                                      course: course,
                                      progress: progress,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CourseDetailScreen(
                                              course: course,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No courses found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedDifficulty: _selectedDifficulty,
        onCategoryChanged: _onCategoryChanged,
        onDifficultyChanged: _onDifficultyChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final String selectedCategory;
  final String selectedDifficulty;
  final Function(String) onCategoryChanged;
  final Function(String) onDifficultyChanged;
  final VoidCallback onClearFilters;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Courses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Categories
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<CourseProvider>(
            builder: (context, courseProvider, child) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChipWidget(
                    label: 'All',
                    isSelected: selectedCategory.isEmpty,
                    onTap: () => onCategoryChanged(''),
                  ),
                  ...courseProvider.categories.map((category) => FilterChipWidget(
                    label: category.name,
                    isSelected: selectedCategory == category.id,
                    onTap: () => onCategoryChanged(category.id),
                  )),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Difficulty
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChipWidget(
                label: 'All',
                isSelected: selectedDifficulty.isEmpty,
                onTap: () => onDifficultyChanged(''),
              ),
              FilterChipWidget(
                label: 'Beginner',
                isSelected: selectedDifficulty == 'Beginner',
                onTap: () => onDifficultyChanged('Beginner'),
              ),
              FilterChipWidget(
                label: 'Intermediate',
                isSelected: selectedDifficulty == 'Intermediate',
                onTap: () => onDifficultyChanged('Intermediate'),
              ),
              FilterChipWidget(
                label: 'Advanced',
                isSelected: selectedDifficulty == 'Advanced',
                onTap: () => onDifficultyChanged('Advanced'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    onClearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

