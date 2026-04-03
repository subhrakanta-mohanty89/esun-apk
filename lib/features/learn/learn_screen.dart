/// ESUN Financial Learning Hub
///
/// Documentaries, videos, courses and learning content
/// related to finance, investment, and trading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  final _categories = ['All', 'Investing', 'Trading', 'Budgeting', 'Tax', 'Insurance', 'Crypto'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Category Filter Chips
                _buildCategoryChips(),
                const SizedBox(height: 8),
                // Tab Bar
                _buildTabBar(),
              ],
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosTab(),
                _buildCoursesTab(),
                _buildArticlesTab(),
                _buildDocumentariesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: ESUNColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3370), Color(0xFF2E4A9A), Color(0xFF4A62B8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.xl, ESUNSpacing.massive, ESUNSpacing.xl, ESUNSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Learning Hub',
                              style: ESUNTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Master your money with expert knowledge',
                              style: ESUNTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: const Text('Learn', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: ESUNColors.primary.withOpacity(0.12),
              checkmarkColor: ESUNColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? ESUNColors.primary.withOpacity(0.3) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ESUNColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ESUNColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Videos'),
          Tab(text: 'Courses'),
          Tab(text: 'Articles'),
          Tab(text: 'Docs'),
        ],
      ),
    );
  }

  // ─── Videos Tab ───
  Widget _buildVideosTab() {
    final videos = _getFilteredVideos();
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: videos.length,
      itemBuilder: (context, index) => _buildVideoCard(videos[index]),
    );
  }

  Widget _buildVideoCard(_LearnItem item) {
    return GestureDetector(
      onTap: () => _openContent(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.color.withOpacity(0.8), item.color],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.9), size: 56),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.duration, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // Free/Premium badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(
                        color: item.isFree ? Colors.green : Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isFree ? 'FREE' : 'PRO',
                        style: TextStyle(color: item.isFree ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600), maxLines: 2),
                  const SizedBox(height: 4),
                  Text(item.description, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: ESUNColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(item.author, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.visibility_outlined, size: 14, color: ESUNColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(item.views, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
                      const Spacer(),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: i < item.rating ? Colors.amber : Colors.grey.shade300,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Courses Tab ───
  Widget _buildCoursesTab() {
    final courses = _getCourses();
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: courses.length,
      itemBuilder: (context, index) => _buildCourseCard(courses[index]),
    );
  }

  Widget _buildCourseCard(_CourseItem course) {
    return GestureDetector(
      onTap: () => _showCourseDetail(course),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [course.color.withOpacity(0.8), course.color]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(course.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(course.subtitle, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildCourseMeta(Icons.book_outlined, '${course.lessons} lessons'),
                      const SizedBox(width: 12),
                      _buildCourseMeta(Icons.timer_outlined, course.duration),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: course.level == 'Beginner' ? Colors.green.withOpacity(0.1) :
                                 course.level == 'Intermediate' ? Colors.orange.withOpacity(0.1) :
                                 Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.level,
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: course.level == 'Beginner' ? Colors.green :
                                   course.level == 'Intermediate' ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (course.progress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: course.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(course.color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ESUNColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 10, color: ESUNColors.textSecondary)),
      ],
    );
  }

  // ─── Articles Tab ───
  Widget _buildArticlesTab() {
    final articles = _getArticles();
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: articles.length,
      itemBuilder: (context, index) => _buildArticleCard(articles[index]),
    );
  }

  Widget _buildArticleCard(_ArticleItem article) {
    return GestureDetector(
      onTap: () => _showArticleDetail(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: ESUNSpacing.tagInsets,
                    decoration: BoxDecoration(
                      color: article.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(article.category, style: TextStyle(fontSize: 10, color: article.color, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(article.title, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600), maxLines: 2),
                  const SizedBox(height: 4),
                  Text(article.preview, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(article.readTime, style: const TextStyle(fontSize: 11, color: ESUNColors.textSecondary)),
                      const SizedBox(width: 8),
                      const Text('·', style: TextStyle(color: ESUNColors.textSecondary)),
                      const SizedBox(width: 8),
                      Text(article.date, style: const TextStyle(fontSize: 11, color: ESUNColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [article.color.withOpacity(0.7), article.color]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(article.icon, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Documentaries Tab ───
  Widget _buildDocumentariesTab() {
    final docs = _getDocumentaries();
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: docs.length,
      itemBuilder: (context, index) => _buildDocumentaryCard(docs[index]),
    );
  }

  Widget _buildDocumentaryCard(_LearnItem item) {
    return GestureDetector(
      onTap: () => _openContent(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [item.color.withOpacity(0.7), item.color],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 8),
                        Text('Watch Documentary', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text(item.duration, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text('Featured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item.description, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary), maxLines: 3),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDocMeta(Icons.movie_outlined, item.category),
                      const SizedBox(width: 16),
                      _buildDocMeta(Icons.language, item.author),
                      const Spacer(),
                      Container(
                        padding: ESUNSpacing.chipInsets,
                        decoration: BoxDecoration(
                          color: ESUNColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Watch', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ESUNColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: ESUNColors.textSecondary)),
      ],
    );
  }

  // ─── Actions ───
  void _openContent(_LearnItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  children: [
                    // Video placeholder
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [item.color.withOpacity(0.8), item.color]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 64)),
                    ),
                    const SizedBox(height: 16),
                    Text(item.title, style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: ESUNColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(item.author, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer, size: 16, color: ESUNColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(item.duration, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(item.description, style: ESUNTypography.bodyMedium.copyWith(height: 1.6)),
                    const SizedBox(height: 16),
                    // Key Topics
                    Text('Key Topics', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: item.color.withOpacity(0.1),
                        side: BorderSide(color: item.color.withOpacity(0.2)),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Watch button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening ${item.title}...')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Learning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseDetail(_CourseItem course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [course.color.withOpacity(0.8), course.color]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(course.icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('${course.lessons} lessons · ${course.duration}', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(course.subtitle, style: ESUNTypography.bodyMedium),
                    const SizedBox(height: 16),
                    Text('Course Content', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...List.generate(course.lessons, (i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: i < (course.progress * course.lessons).round() ? course.color : Colors.grey.shade200,
                        child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: i < (course.progress * course.lessons).round() ? Colors.white : Colors.grey)),
                      ),
                      title: Text('Lesson ${i + 1}', style: ESUNTypography.bodyMedium),
                      subtitle: Text(course.lessonTitles.length > i ? course.lessonTitles[i] : 'Coming soon', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      trailing: Icon(
                        i < (course.progress * course.lessons).round() ? Icons.check_circle : Icons.play_circle_outline,
                        color: i < (course.progress * course.lessons).round() ? Colors.green : Colors.grey,
                      ),
                    )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: course.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(course.progress > 0 ? 'Continue Learning' : 'Start Course'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleDetail(_ArticleItem article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  children: [
                    Container(
                      padding: ESUNSpacing.badgeInsets,
                      decoration: BoxDecoration(color: article.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(article.category, style: TextStyle(fontSize: 12, color: article.color, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Text(article.title, style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(article.readTime, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: ESUNColors.textSecondary)),
                        const SizedBox(width: 8),
                        Text(article.date, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(article.content, style: ESUNTypography.bodyMedium.copyWith(height: 1.7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Data ───
  List<_LearnItem> _getFilteredVideos() {
    final all = [
      const _LearnItem(
        title: 'Mutual Funds for Beginners – Complete Guide',
        description: 'Learn how mutual funds work, types of funds (equity, debt, hybrid), SIPs, and how to choose the right fund for your goals.',
        author: 'CA Rachana Ranade',
        duration: '28:45',
        category: 'Investing',
        views: '2.4M',
        rating: 5,
        color: Color(0xFF059669),
        isFree: true,
        tags: ['Mutual Funds', 'SIP', 'Equity', 'Debt Funds'],
      ),
      const _LearnItem(
        title: 'Stock Market Basics – How to Start Trading',
        description: 'Understand the stock market from scratch: NSE, BSE, demat accounts, reading charts, placing orders, and risk management.',
        author: 'Pranjal Kamra',
        duration: '35:12',
        category: 'Trading',
        views: '3.1M',
        rating: 5,
        color: Color(0xFF2563EB),
        isFree: true,
        tags: ['Stocks', 'NSE', 'BSE', 'Trading'],
      ),
      const _LearnItem(
        title: 'Income Tax Planning – Save More Legally',
        description: 'Master Section 80C, 80D, HRA exemptions, NPS benefits, and advanced strategies to minimize your tax outgo.',
        author: 'Akshat Shrivastava',
        duration: '22:30',
        category: 'Tax',
        views: '1.8M',
        rating: 4,
        color: Color(0xFFF59E0B),
        isFree: true,
        tags: ['Tax Saving', '80C', '80D', 'NPS'],
      ),
      const _LearnItem(
        title: 'The 50/30/20 Budgeting Rule Explained',
        description: 'A simple and effective budgeting framework: 50% needs, 30% wants, 20% savings. Practical tips for Indian salaries.',
        author: 'Warikoo',
        duration: '15:40',
        category: 'Budgeting',
        views: '5.2M',
        rating: 5,
        color: Color(0xFF8B5CF6),
        isFree: true,
        tags: ['Budgeting', 'Saving', 'Money Management'],
      ),
      const _LearnItem(
        title: 'Understanding Health & Term Insurance',
        description: 'Why you need adequate health and term insurance, how to calculate cover, and common mistakes to avoid.',
        author: 'Labour Law Advisor',
        duration: '19:15',
        category: 'Insurance',
        views: '1.2M',
        rating: 4,
        color: Color(0xFFEF4444),
        isFree: true,
        tags: ['Health Insurance', 'Term Insurance', 'Cover'],
      ),
      const _LearnItem(
        title: 'Options Trading Masterclass',
        description: 'Deep dive into call & put options, option Greeks, spreads, straddles, and real-world strategies with risk management.',
        author: 'Power of Stocks',
        duration: '1:12:00',
        category: 'Trading',
        views: '890K',
        rating: 4,
        color: Color(0xFF0891B2),
        isFree: false,
        tags: ['Options', 'Greeks', 'Strategies', 'Risk'],
      ),
      const _LearnItem(
        title: 'Real Estate Investing in India 2026',
        description: 'Should you buy or rent? REITs vs physical property. Tax implications, rental yields, and market outlook.',
        author: 'Shankar Nath',
        duration: '32:20',
        category: 'Investing',
        views: '670K',
        rating: 4,
        color: Color(0xFF7C3AED),
        isFree: true,
        tags: ['Real Estate', 'REITs', 'Property', 'Rent vs Buy'],
      ),
      const _LearnItem(
        title: 'Cryptocurrency Basics for Indians',
        description: 'Bitcoin, Ethereum, blockchain technology explained. Tax on crypto in India, exchanges, and safe investing practices.',
        author: 'Pushkar Raj Thakur',
        duration: '25:00',
        category: 'Crypto',
        views: '2.1M',
        rating: 4,
        color: Color(0xFFEC4899),
        isFree: true,
        tags: ['Bitcoin', 'Ethereum', 'Blockchain', 'Crypto Tax'],
      ),
    ];
    if (_selectedCategory == 'All') return all;
    return all.where((v) => v.category == _selectedCategory).toList();
  }

  List<_CourseItem> _getCourses() {
    return [
      const _CourseItem(
        title: 'Personal Finance 101',
        subtitle: 'Build a solid foundation in managing your money — from budgeting and saving to investing and planning for retirement.',
        icon: Icons.account_balance_wallet_outlined,
        color: Color(0xFF2E4A9A),
        lessons: 8,
        duration: '2h 30m',
        level: 'Beginner',
        progress: 0.25,
        lessonTitles: ['Why Personal Finance Matters', 'Tracking Income & Expenses', 'Building an Emergency Fund', 'Understanding Debt', 'Introduction to Investing', 'Tax Saving Basics', 'Setting Financial Goals', 'Creating Your Plan'],
      ),
      const _CourseItem(
        title: 'Stock Market Investing',
        subtitle: 'Learn to analyze stocks, read financial statements, understand valuations, and build a long-term equity portfolio.',
        icon: Icons.trending_up_rounded,
        color: Color(0xFF059669),
        lessons: 12,
        duration: '4h 15m',
        level: 'Intermediate',
        progress: 0.0,
        lessonTitles: ['How Stock Markets Work', 'Reading Financial Statements', 'Fundamental Analysis', 'Technical Analysis Basics', 'Valuation Methods', 'Building a Portfolio', 'Sector Analysis', 'Risk Management', 'Dividend Investing', 'Growth vs Value', 'When to Buy & Sell', 'Portfolio Review'],
      ),
      const _CourseItem(
        title: 'Mutual Fund Mastery',
        subtitle: 'From choosing the right fund to SIP strategies, learn everything about mutual fund investing in India.',
        icon: Icons.pie_chart_outline_rounded,
        color: Color(0xFFF59E0B),
        lessons: 6,
        duration: '1h 45m',
        level: 'Beginner',
        progress: 0.5,
        lessonTitles: ['What Are Mutual Funds', 'Types of Mutual Funds', 'SIP vs Lumpsum', 'How to Choose a Fund', 'Tax on Mutual Funds', 'Building Your MF Portfolio'],
      ),
      const _CourseItem(
        title: 'Trading Strategies',
        subtitle: 'Master intraday, swing trading, and positional trading with chart patterns, indicators, and risk management.',
        icon: Icons.candlestick_chart_outlined,
        color: Color(0xFFEF4444),
        lessons: 15,
        duration: '6h 00m',
        level: 'Advanced',
        progress: 0.0,
        lessonTitles: ['Introduction to Trading', 'Candlestick Patterns', 'Support & Resistance', 'Moving Averages', 'RSI & MACD', 'Volume Analysis', 'Intraday Strategies', 'Swing Trading', 'Options Basics', 'Option Strategies', 'Risk Management', 'Position Sizing', 'Trading Psychology', 'Building a Trading Plan', 'Backtesting'],
      ),
      const _CourseItem(
        title: 'Tax Planning & Filing',
        subtitle: 'Optimize your taxes legally using all available deductions, exemptions, and investment strategies.',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF8B5CF6),
        lessons: 7,
        duration: '2h 00m',
        level: 'Intermediate',
        progress: 0.0,
        lessonTitles: ['Understanding ITR Forms', 'Section 80C Deep Dive', 'HRA & Home Loan Benefits', 'Capital Gains Tax', 'NPS Tax Benefits', 'Filing Your Return', 'Common Mistakes to Avoid'],
      ),
    ];
  }

  List<_ArticleItem> _getArticles() {
    return [
      const _ArticleItem(
        title: 'Emergency Fund: How Much Do You Really Need?',
        preview: 'Most experts recommend 6 months of expenses, but the right amount depends on your job stability, dependents, and lifestyle...',
        content: 'An emergency fund is the foundation of your financial plan. It\'s money set aside for unexpected expenses — job loss, medical emergencies, or urgent repairs.\n\nHow much should you save?\n\nThe standard recommendation is 3-6 months of monthly expenses. However, consider these factors:\n\n• Single income household: Aim for 6-9 months\n• Dual income, no dependents: 3-4 months may suffice\n• Freelancers or variable income: 9-12 months is safer\n• High-risk industry: Consider up to 12 months\n\nWhere to keep your emergency fund:\n\n1. Savings account (instant access)\n2. Liquid mutual funds (slightly better returns)\n3. Short-term FDs (with premature withdrawal)\n\nNever invest your emergency fund in stocks, mutual funds with lock-in, or illiquid assets. The purpose is quick access, not high returns.\n\nStart small — even ₹5,000/month adds up. Set up an auto-transfer on salary day so you pay yourself first.',
        category: 'Budgeting',
        readTime: '5 min read',
        date: 'Mar 18, 2026',
        icon: Icons.savings_outlined,
        color: Color(0xFF059669),
      ),
      const _ArticleItem(
        title: 'ELSS vs PPF vs NPS: Which is Best for Tax Saving?',
        preview: 'Compare the top Section 80C instruments on returns, lock-in, liquidity, and tax treatment...',
        content: 'When it comes to tax saving under Section 80C (up to ₹1.5 lakh), you have several options. Let\'s compare the top three:\n\nELSS (Equity Linked Savings Scheme)\n• Lock-in: 3 years (shortest)\n• Expected returns: 12-15% CAGR\n• Tax on returns: 10% LTCG above ₹1 lakh\n• Suitable for: Moderate to high risk takers\n\nPPF (Public Provident Fund)\n• Lock-in: 15 years\n• Returns: 7.1% (government fixed)\n• Tax on returns: Exempt (EEE status)\n• Suitable for: Conservative investors\n\nNPS (National Pension System)\n• Lock-in: Till age 60\n• Expected returns: 9-12%\n• Additional deduction: ₹50,000 under 80CCD(1B)\n• Tax on returns: Partially taxable\n• Suitable for: Long-term retirement planning\n\nVerdict: For maximum tax saving with flexibility, ELSS is best. For guaranteed safety, PPF. For additional deduction, add NPS to your portfolio.',
        category: 'Tax',
        readTime: '7 min read',
        date: 'Mar 15, 2026',
        icon: Icons.compare_arrows_outlined,
        color: Color(0xFFF59E0B),
      ),
      const _ArticleItem(
        title: 'Reading a Company Balance Sheet in 10 Minutes',
        preview: 'A practical guide to quickly analyze a company\'s financial health using just the balance sheet...',
        content: 'Before investing in any stock, you must understand its balance sheet. Here\'s how to read one in 10 minutes:\n\n1. Total Assets: What the company owns\n   - Current Assets (cash, receivables, inventory)\n   - Non-current Assets (property, equipment, goodwill)\n\n2. Total Liabilities: What the company owes\n   - Current Liabilities (payables, short-term debt)\n   - Non-current Liabilities (long-term debt, bonds)\n\n3. Shareholders\' Equity: Net worth = Assets - Liabilities\n\nKey Ratios to Check:\n• Debt-to-Equity: Below 1 is generally good\n• Current Ratio: Above 1.5 shows good liquidity\n• Return on Equity (ROE): Above 15% is attractive\n\nRed flags:\n- Increasing debt year-over-year\n- Declining cash reserves\n- Growing receivables (customers not paying)\n- Inventory pile-up\n\nAlways compare ratios with industry peers, not in isolation.',
        category: 'Investing',
        readTime: '8 min read',
        date: 'Mar 12, 2026',
        icon: Icons.analytics_outlined,
        color: Color(0xFF2563EB),
      ),
      const _ArticleItem(
        title: 'What is SIP and Why Should You Start One Today',
        preview: 'Systematic Investment Plans automate your investing journey and help build wealth through rupee cost averaging...',
        content: 'A Systematic Investment Plan (SIP) is the easiest way to start investing. You invest a fixed amount regularly (monthly/weekly) into a mutual fund.\n\nWhy SIP works:\n\n1. Rupee Cost Averaging: You buy more units when prices are low and fewer when high, averaging out your cost.\n\n2. Power of Compounding: ₹5,000/month at 12% for 20 years = ₹49.9 lakhs (invested only ₹12 lakhs)\n\n3. Discipline: Auto-debit means you invest consistently without emotional decisions.\n\n4. Start Small: Begin with just ₹500/month.\n\nHow to choose a SIP:\n• For 3-5 years: Debt or hybrid funds\n• For 5-10 years: Large-cap or flexi-cap funds\n• For 10+ years: Mid-cap or small-cap funds\n\nTop tip: Increase your SIP by 10% every year (step-up SIP) to accelerate wealth building.',
        category: 'Investing',
        readTime: '4 min read',
        date: 'Mar 10, 2026',
        icon: Icons.auto_graph_outlined,
        color: Color(0xFF7C3AED),
      ),
      const _ArticleItem(
        title: 'Health Insurance: 5 Mistakes People Make',
        preview: 'Don\'t fall into these common traps when buying health insurance for your family...',
        content: 'Health insurance is not optional — it\'s essential. But many people make these mistakes:\n\n1. Insufficient Cover\nDon\'t buy just ₹3-5 lakhs. With medical inflation at 14%, get at least ₹10-20 lakhs. Use a base plan + super top-up combo.\n\n2. Waiting Till You\'re Older\nBuy early! Premiums are 2-3x higher after 40. Pre-existing diseases have waiting periods.\n\n3. Relying Only on Employer Cover\nCorporate insurance ends when you leave. Get your own policy alongside.\n\n4. Ignoring Sub-limits\nSome policies have room rent caps (1-2% of sum insured). Read the fine print.\n\n5. Not Considering Family Floater\nA family floater plan is cheaper than individual plans for each family member. But ensure the total sum insured is adequate.\n\nBonus Tip: Always add a critical illness rider for diseases like cancer, heart attack, and stroke.',
        category: 'Insurance',
        readTime: '6 min read',
        date: 'Mar 8, 2026',
        icon: Icons.health_and_safety_outlined,
        color: Color(0xFFEF4444),
      ),
    ];
  }

  List<_LearnItem> _getDocumentaries() {
    final all = [
      const _LearnItem(
        title: 'The Big Short – How the 2008 Crash Happened',
        description: 'Explore the story of how a few wall street outsiders predicted and profited from the subprime mortgage crisis, revealing the corruption and greed that led to the global financial meltdown.',
        author: 'Financial Times',
        duration: '1:45:00',
        category: 'Investing',
        views: '12M',
        rating: 5,
        color: Color(0xFF1E3A5F),
        isFree: true,
        tags: ['2008 Crisis', 'Wall Street', 'Subprime', 'Financial History'],
      ),
      const _LearnItem(
        title: 'Inside the Mind of Warren Buffett',
        description: 'A deep dive into the investment philosophy, strategies, and life lessons of the Oracle of Omaha. Learn value investing, patience, and the art of compound growth.',
        author: 'HBO Documentary',
        duration: '1:28:00',
        category: 'Investing',
        views: '8.5M',
        rating: 5,
        color: Color(0xFF059669),
        isFree: true,
        tags: ['Warren Buffett', 'Value Investing', 'Berkshire', 'Compounding'],
      ),
      const _LearnItem(
        title: 'Scam 1992 – Harshad Mehta & The Indian Stock Market',
        description: 'The incredible true story of Harshad Mehta who manipulated the Indian stock market in 1992 using bank receipts and stamping paper frauds. A lesson in market manipulation.',
        author: 'SonyLIV',
        duration: '2:15:00',
        category: 'Trading',
        views: '15M',
        rating: 5,
        color: Color(0xFFC2410C),
        isFree: false,
        tags: ['Harshad Mehta', 'BSE', 'Market Manipulation', 'Indian Markets'],
      ),
      const _LearnItem(
        title: 'Money Explained – How Banking Really Works',
        description: 'From fractional reserve banking to central bank policies, understand how money is created, managed, and how it affects your daily life and investments.',
        author: 'Netflix',
        duration: '52:00',
        category: 'Budgeting',
        views: '4.2M',
        rating: 4,
        color: Color(0xFF7C3AED),
        isFree: false,
        tags: ['Banking', 'Money Creation', 'RBI', 'Interest Rates'],
      ),
      const _LearnItem(
        title: 'Crypto Revolution – The Future of Money?',
        description: 'Is cryptocurrency the next evolution of money? Explore Bitcoin\'s creation, blockchain technology, DeFi, and what it means for traditional finance in India.',
        author: 'Vice Documentary',
        duration: '1:05:00',
        category: 'Crypto',
        views: '6.8M',
        rating: 4,
        color: Color(0xFFEC4899),
        isFree: true,
        tags: ['Bitcoin', 'Blockchain', 'DeFi', 'Future of Money'],
      ),
    ];
    if (_selectedCategory == 'All') return all;
    return all.where((d) => d.category == _selectedCategory).toList();
  }
}

// ─── Data Models ───

class _LearnItem {
  final String title;
  final String description;
  final String author;
  final String duration;
  final String category;
  final String views;
  final int rating;
  final Color color;
  final bool isFree;
  final List<String> tags;

  const _LearnItem({
    required this.title,
    required this.description,
    required this.author,
    required this.duration,
    required this.category,
    required this.views,
    required this.rating,
    required this.color,
    required this.isFree,
    this.tags = const [],
  });
}

class _CourseItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int lessons;
  final String duration;
  final String level;
  final double progress;
  final List<String> lessonTitles;

  const _CourseItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lessons,
    required this.duration,
    required this.level,
    required this.progress,
    this.lessonTitles = const [],
  });
}

class _ArticleItem {
  final String title;
  final String preview;
  final String content;
  final String category;
  final String readTime;
  final String date;
  final IconData icon;
  final Color color;

  const _ArticleItem({
    required this.title,
    required this.preview,
    required this.content,
    required this.category,
    required this.readTime,
    required this.date,
    required this.icon,
    required this.color,
  });
}
