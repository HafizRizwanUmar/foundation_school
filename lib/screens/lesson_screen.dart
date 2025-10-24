import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/course_model.dart';
import '../providers/progress_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/ad_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/lesson_navigation_widget.dart';

class LessonScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;
  final int lessonIndex;

  const LessonScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.lessonIndex,
  });

  @override
  State<LessonScreen> createState() => _ImprovedLessonScreenState();
}

class _ImprovedLessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _progressAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  double _readingProgress = 0.0;
  int _studyTimeSeconds = 0;
  DateTime? _lessonStartTime;
  bool _hasMarkedAsRead = false;
  bool _isBookmarked = false;
  bool _showFloatingPlayer = false;
  int _selectedTabIndex = 0;

  // HCI: Color scheme following Material Design 3 principles
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onSurfaceColor = Color(0xFF1F2937);
  static const Color accentColor = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _lessonStartTime = DateTime.now();

    // HCI: Smooth animations for better user feedback
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeOutCubic),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutQuart),
    );

    _scrollController.addListener(_onScroll);

    // HCI: Immediate visual feedback on screen load
    _headerAnimationController.forward();
    _fabAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).initialize();
    });

    _startStudyTimeTracking();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _progressAnimationController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _saveProgress();
    super.dispose();
  }

  // HCI: Enhanced scroll feedback with haptic response
  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      setState(() {
        _readingProgress = progress;
      });

      // HCI: Haptic feedback at progress milestones
      if (progress >= 0.25 && progress < 0.26) {
        HapticFeedback.lightImpact();
      } else if (progress >= 0.5 && progress < 0.51) {
        HapticFeedback.mediumImpact();
      } else if (progress >= 0.75 && progress < 0.76) {
        HapticFeedback.heavyImpact();
      }

      if (progress >= 0.8 && !_hasMarkedAsRead) {
        _markLessonAsRead();
      }
    }
  }

  void _startStudyTimeTracking() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _studyTimeSeconds += 10;
        _updateProgress();
        _startStudyTimeTracking();
      }
    });
  }

  void _markLessonAsRead() {
    if (_hasMarkedAsRead) return;

    setState(() {
      _hasMarkedAsRead = true;
      _readingProgress = 1.0;
    });

    // HCI: Success feedback with animation and haptics
    _progressAnimationController.forward();
    HapticFeedback.mediumImpact();
    _completeLesson();
  }

  void _completeLesson() {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final studyTimeMinutes = (_studyTimeSeconds / 60).ceil();

    progressProvider.completeLesson(
      widget.course.id,
      widget.lesson.id,
      studyTimeMinutes,
      course: widget.course,
    );

    adProvider.showInterstitialAd(
      onAdClosed: () {
        debugPrint('Interstitial ad closed after lesson completion');
      },
    );

    adProvider.onLessonCompleted();
  }

  void _updateProgress() {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    final studyTimeMinutes = (_studyTimeSeconds / 60).ceil();

    progressProvider.updateLessonProgress(
      widget.course.id,
      widget.lesson.id,
      _readingProgress * 100,
      studyTimeMinutes,
    );
  }

  void _saveProgress() {
    if (_lessonStartTime != null) {
      final totalStudyTime = DateTime.now().difference(_lessonStartTime!).inSeconds;
      _studyTimeSeconds = totalStudyTime;
      _updateProgress();
    }
  }

  // HCI: Improved bookmark functionality with visual feedback
  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(_isBookmarked ? 'Lesson bookmarked' : 'Bookmark removed'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isBookmarked ? successColor : Colors.grey[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // HCI: Enhanced app bar with better visual hierarchy
          _buildEnhancedAppBar(),
          
          // HCI: Improved content layout with better spacing
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    // Hero section with lesson overview
                    _buildHeroSection(),
                    
                    // Tabbed content organization
                    _buildTabSection(),
                    
                    // Content based on selected tab
                    _buildTabContent(),
                    
                    const SizedBox(height: 120), // Space for FABs
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // HCI: Floating action buttons for quick navigation
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // HCI: Bookmark button with visual feedback
        AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _headerAnimation.value,
              child: IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleBookmark,
              ),
            );
          },
        ),
        
        // Audio settings
        Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return IconButton(
              icon: Icon(
                audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () => _toggleAudio(audioProvider),
            );
          },
        ),
        
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'audio_settings',
              child: Row(
                children: [
                  Icon(Icons.settings_voice),
                  SizedBox(width: 8),
                  Text('Audio Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share Lesson'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, accentColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course breadcrumb
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.course.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Lesson title
                          Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Progress and info row
                          Row(
                            children: [
                              // Circular progress indicator
                              Consumer<ProgressProvider>(
                                builder: (context, progressProvider, child) {
                                  final lessonProgress = progressProvider.getLessonProgressPercentage(
                                    widget.course.id,
                                    widget.lesson.id,
                                  );
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      children: [
                                        CircularProgressIndicator(
                                          value: lessonProgress / 100,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 4,
                                        ),
                                        Center(
                                          child: Text(
                                            '${lessonProgress.toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 20),
                              
                              // Lesson info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoChip(
                                      Icons.schedule,
                                      '${widget.lesson.duration} min read',
                                      Colors.white.withOpacity(0.2),
                                      Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoChip(
                                      Icons.article,
                                      widget.lesson.type,
                                      Colors.white.withOpacity(0.2),
                                      Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_filled,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap play to listen while reading',
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Enhanced audio player
          _buildEnhancedAudioPlayer(),
          
          const SizedBox(height: 20),
          
          // Reading progress
          _buildReadingProgress(),
        ],
      ),
    );
  }

  Widget _buildEnhancedAudioPlayer() {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isCurrentlyPlaying = audioProvider.currentText == widget.lesson.content && audioProvider.isPlaying;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () => _toggleAudio(audioProvider),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Waveform visualization (simplified)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(20, (index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 3,
                          height: isCurrentlyPlaying 
                            ? (10 + (index % 3) * 5).toDouble()
                            : 8,
                          decoration: BoxDecoration(
                            color: isCurrentlyPlaying 
                              ? primaryColor 
                              : primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCurrentlyPlaying ? 'Playing...' : 'Tap to play audio',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Duration
              Text(
                '${widget.lesson.duration}:00',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(_readingProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('Content', 0, Icons.article),
          _buildTabButton('Key Points', 1, Icons.lightbulb_outline),
          _buildTabButton('Resources', 2, Icons.link),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : onSurfaceColor.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : onSurfaceColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildLessonContent();
      case 1:
        return _buildKeyPoints();
      case 2:
        return _buildResources();
      default:
        return _buildLessonContent();
    }
  }

  Widget _buildLessonContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lesson Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
          
          const SizedBox(height: 20),
          
          SelectableText(
            widget.lesson.content,
            style: TextStyle(
              height: 1.8,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: onSurfaceColor,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.justify,
          ),
          
          const SizedBox(height: 24),
          
          // Completion button
          _buildCompletionButton(),
        ],
      ),
    );
  }

  Widget _buildKeyPoints() {
    if (widget.lesson.keyPoints.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No key points available for this lesson.',
            style: TextStyle(
              color: onSurfaceColor.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: widget.lesson.keyPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: onSurfaceColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResources() {
    if (widget.lesson.resources.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No additional resources available for this lesson.',
            style: TextStyle(
              color: onSurfaceColor.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: widget.lesson.resources.map((resource) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getResourceIcon(resource.type),
                  color: primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                resource.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onSurfaceColor,
                ),
              ),
              trailing: Icon(
                Icons.open_in_new,
                size: 18,
                color: onSurfaceColor.withOpacity(0.6),
              ),
              onTap: () {
                // Launch URL
                HapticFeedback.lightImpact();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionButton() {
    return Consumer2<ProgressProvider, AdProvider>(
      builder: (context, progressProvider, adProvider, child) {
        final isCompleted = progressProvider.isLessonCompleted(
          widget.course.id,
          widget.lesson.id,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isCompleted ? null : () => _showRewardedAdAndComplete(adProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? successColor : primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isCompleted ? 0 : 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Lesson Completed!' : 'Complete Lesson',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous lesson
              if (widget.lessonIndex > 0)
                FloatingActionButton(
                  heroTag: "previous",
                  onPressed: _goToPreviousLesson,
                  backgroundColor: surfaceColor,
                  foregroundColor: primaryColor,
                  child: const Icon(Icons.arrow_back_ios),
                ),
              
              // Course overview
              FloatingActionButton(
                heroTag: "overview",
                onPressed: () => Navigator.pop(context),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.list),
              ),
              
              // Next lesson
              if (widget.lessonIndex < widget.course.lessons.length - 1)
                FloatingActionButton(
                  heroTag: "next",
                  onPressed: _goToNextLesson,
                  backgroundColor: surfaceColor,
                  foregroundColor: primaryColor,
                  child: const Icon(Icons.arrow_forward_ios),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'download':
        return Icons.download;
      default:
        return Icons.link;
    }
  }

  void _toggleAudio(AudioProvider audioProvider) {
    if (audioProvider.currentText == widget.lesson.content && audioProvider.isPlaying) {
      audioProvider.pause();
    } else if (audioProvider.currentText == widget.lesson.content && audioProvider.isPaused) {
      audioProvider.resume();
    } else {
      audioProvider.speakText(widget.lesson.content);
    }
    HapticFeedback.lightImpact();
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'audio_settings':
        _showAudioSettings();
        break;
      case 'share':
        _shareLesson();
        break;
    }
  }

  void _shareLesson() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Text('Lesson shared successfully!'),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAudioSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AudioSettingsBottomSheet(),
    );
  }

  void _showRewardedAdAndComplete(AdProvider adProvider) {
    HapticFeedback.mediumImpact();
    adProvider.showRewardedAd(
      onRewardEarned: () {
        _markLessonAsRead();
        _showLessonCompletionDialog();
      },
      onAdClosed: () {
        if (!_hasMarkedAsRead) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Please watch the complete ad to finish the lesson.'),
                ],
              ),
              backgroundColor: secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );
  }

  void _showLessonCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: successColor, size: 32),
            const SizedBox(width: 12),
            const Text('Lesson Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations! You have successfully completed this lesson.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: secondaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'You earned bonus points!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _goToPreviousLesson() {
    if (widget.lessonIndex > 0) {
      HapticFeedback.lightImpact();
      final previousLesson = widget.course.lessons[widget.lessonIndex - 1];
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LessonScreen(
            course: widget.course,
            lesson: previousLesson,
            lessonIndex: widget.lessonIndex - 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _goToNextLesson() {
    HapticFeedback.lightImpact();
    if (widget.lessonIndex < widget.course.lessons.length - 1) {
      final nextLesson = widget.course.lessons[widget.lessonIndex + 1];
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LessonScreen(
            course: widget.course,
            lesson: nextLesson,
            lessonIndex: widget.lessonIndex + 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      _showCourseCompletionDialog();
    }
  }

  void _showCourseCompletionDialog() {
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    
    if (adProvider.isRewardedAdLoaded) {
      adProvider.showRewardedAd(
        onRewardEarned: () {
          _showCourseCompletedDialog(earnedReward: true);
          adProvider.onCourseCompleted();
        },
        onAdClosed: () {
          _showCourseCompletedDialog(earnedReward: false);
          adProvider.onCourseCompleted();
        },
      );
    } else {
      _showCourseCompletedDialog(earnedReward: false);
      adProvider.onCourseCompleted();
    }
  }

  void _showCourseCompletedDialog({bool earnedReward = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: secondaryColor, size: 32),
            const SizedBox(width: 12),
            const Text('Course Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Congratulations! You have completed all lessons in this course. Great job on your learning journey!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (earnedReward) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: secondaryColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Course completed! You earned achievement points!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Course'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Explore More'),
          ),
        ],
      ),
    );
  }
}

// Enhanced Audio Settings Bottom Sheet
class AudioSettingsBottomSheet extends StatelessWidget {
  const AudioSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Audio Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              return Column(
                children: [
                  _buildSliderSetting(
                    'Speech Rate',
                    audioProvider.speechRate,
                    0.1,
                    1.0,
                    9,
                    audioProvider.setSpeechRate,
                    '${(audioProvider.speechRate * 100).toInt()}%',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSliderSetting(
                    'Speech Pitch',
                    audioProvider.speechPitch,
                    0.5,
                    2.0,
                    15,
                    audioProvider.setSpeechPitch,
                    '${(audioProvider.speechPitch * 100).toInt()}%',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSliderSetting(
                    'Volume',
                    audioProvider.speechVolume,
                    0.0,
                    1.0,
                    10,
                    audioProvider.setSpeechVolume,
                    '${(audioProvider.speechVolume * 100).toInt()}%',
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    int divisions,
    Function(double) onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2563EB),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: const Color(0xFF2563EB),
            overlayColor: const Color(0xFF2563EB).withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

