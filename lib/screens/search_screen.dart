import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/course_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus;
    });
  }

  void _loadSearchHistory() {
    // In a real app, load from SharedPreferences
    setState(() {
      _searchHistory = [
        'ChatGPT',
        'AI Assistants',
        'Image Generation',
        'Video Creation',
      ];
    });
  }

  void _onSearchChanged(String query) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.searchCourses(query);
    
    if (query.isNotEmpty) {
      setState(() {
        _searchSuggestions = courseProvider.getSearchSuggestions(query);
      });
    } else {
      setState(() {
        _searchSuggestions = [];
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _addToSearchHistory(query.trim());
      _searchFocusNode.unfocus();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _addToSearchHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    });
    // In a real app, save to SharedPreferences
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // In a real app, clear from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search courses, AI tools, topics...',
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

          // Content
          Expanded(
            child: _showSuggestions
                ? _buildSuggestionsView()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Suggestions
          if (_searchSuggestions.isNotEmpty) ...[
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: _searchSuggestions.map((suggestion) => ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion),
                onTap: () {
                  _searchController.text = suggestion;
                  _onSearchSubmitted(suggestion);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Search History
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: _searchHistory.map((query) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchHistory.remove(query);
                    });
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _onSearchSubmitted(query);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular Searches
          Text(
            'Popular Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'ChatGPT',
              'Midjourney',
              'AI Assistants',
              'Image Generation',
              'Video Creation',
              'Claude',
              'Synthesia',
            ].map((tag) => ActionChip(
              label: Text(tag),
              onPressed: () {
                _searchController.text = tag;
                _onSearchSubmitted(tag);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer2<CourseProvider, ProgressProvider>(
      builder: (context, courseProvider, progressProvider, child) {
        final searchQuery = courseProvider.searchQuery;
        final filteredCourses = courseProvider.filteredCourses;

        if (searchQuery.isEmpty) {
          return _buildEmptySearchState();
        }

        if (filteredCourses.isEmpty) {
          return _buildNoResultsState(searchQuery);
        }

        return Column(
          children: [
            // Results Count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${filteredCourses.length} results for "$searchQuery"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
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
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for AI courses',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Find courses on ChatGPT, Midjourney, and more',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
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
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              _searchFocusNode.requestFocus();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

