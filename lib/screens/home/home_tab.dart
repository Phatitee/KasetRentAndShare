import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/rental_item_model.dart';
import '../../models/rental_request_model.dart';
import 'widgets/category_button.dart';
import 'widgets/listing_card.dart';
import 'widgets/request_card.dart';
import '../rentals/post_rental_screen.dart';
import '../rentals/post_request_screen.dart';
import '../rentals/item_detail_screen.dart';
import '../rentals/request_details_screen.dart';
import 'package:provider/provider.dart';

/// A wrapper class to hold either a rental item or request in the feed
class FeedItem {
  final RentalItemModel? rentalItem;
  final RentalRequestModel? rentalRequest;
  final DateTime createdAt;

  FeedItem.fromRentalItem(RentalItemModel item)
      : rentalItem = item,
        rentalRequest = null,
        createdAt = item.createdAt;

  FeedItem.fromRentalRequest(RentalRequestModel request)
      : rentalItem = null,
        rentalRequest = request,
        createdAt = request.createdAt;

  bool get isRentalItem => rentalItem != null;
  bool get isRequest => rentalRequest != null;
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KU Bang Khen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tr('home_title'),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.tr('home_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: l.tr('home_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Action Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        title: l.tr('home_post_item'),
                        subtitle: l.tr('home_post_item_sub'),
                        icon: Icons.add_circle_outline,
                        color: AppTheme.primaryTeal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PostRentalScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        title: l.tr('home_request'),
                        subtitle: l.tr('home_request_sub'),
                        icon: Icons.search,
                        color: AppTheme.accentMint,
                        textColor: AppTheme.primaryTeal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PostRequestScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Categories
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.tr('home_categories'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildCategoryChip(l.tr('cat_all'), Icons.apps, '', l),
                        _buildCategoryChip(l.tr('cat_camera'), Icons.camera_alt, 'Camera', l),
                        _buildCategoryChip(l.tr('cat_electronics'), Icons.laptop, 'Electronics', l),
                        _buildCategoryChip(l.tr('cat_fashion'), Icons.checkroom, 'Fashion', l),
                        _buildCategoryChip(l.tr('cat_books'), Icons.menu_book, 'Books', l),
                        _buildCategoryChip(l.tr('cat_sports'), Icons.sports_basketball, 'Sports', l),
                        _buildCategoryChip(l.tr('cat_music'), Icons.music_note, 'Music', l),
                        _buildCategoryChip(l.tr('cat_others'), Icons.category, 'Others', l),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Feed Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory.isEmpty ? l.tr('home_feed') : _selectedCategory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_selectedCategory.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = '');
                        },
                        child: Text(
                          l.tr('home_clear_filter'),
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Combined Feed: Rental Items + Requests
            _buildCombinedFeed(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedFeed() {
    final categoryFilter =
        _selectedCategory.isEmpty ? null : _selectedCategory;

    return StreamBuilder<List<RentalItemModel>>(
      stream: _firestoreService.getRentalItems(category: categoryFilter),
      builder: (context, itemsSnapshot) {
        return StreamBuilder<List<RentalRequestModel>>(
          stream:
              _firestoreService.getRentalRequests(category: categoryFilter),
          builder: (context, requestsSnapshot) {
            // Loading state
            if (itemsSnapshot.connectionState == ConnectionState.waiting &&
                requestsSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            // Combine both lists into feed items
            final List<FeedItem> feedItems = [];

            final items = itemsSnapshot.data ?? [];
            for (final item in items) {
              feedItems.add(FeedItem.fromRentalItem(item));
            }

            final requests = requestsSnapshot.data ?? [];
            for (final request in requests) {
              feedItems.add(FeedItem.fromRentalRequest(request));
            }

            // Sort by newest first
            feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (feedItems.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.dynamic_feed_outlined,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).tr('home_no_posts'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).tr('home_be_first'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Apply search filter
            final filteredItems = _searchQuery.isEmpty
                ? feedItems
                : feedItems.where((fi) {
                    if (fi.isRentalItem) {
                      return fi.rentalItem!.itemName.toLowerCase().contains(_searchQuery) ||
                          fi.rentalItem!.description.toLowerCase().contains(_searchQuery);
                    } else {
                      return fi.rentalRequest!.itemDescription.toLowerCase().contains(_searchQuery);
                    }
                  }).toList();

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feedItem = filteredItems[index];

                    if (feedItem.isRentalItem) {
                      final item = feedItem.rentalItem!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ListingCard(
                          imageUrl: item.imageUrls.isNotEmpty
                              ? item.imageUrls.first
                              : null,
                          itemName: item.itemName,
                          pricePerDay: item.dailyRate,
                          ownerName: AppLocalizations.of(context).tr('owner'),
                          ownerRating: 5.0,
                          isVerified: false,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailScreen(item: item),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      final request = feedItem.rentalRequest!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RequestCard(
                          itemDescription: request.itemDescription,
                          category: request.category,
                          budget: request.estimatedBudget,
                          startDate: request.startDate,
                          endDate: request.endDate,
                          locationName: request.locationName,
                          requesterName: AppLocalizations.of(context).tr('requester'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestDetailsScreen(request: request),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                  childCount: filteredItems.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, String categoryKey, AppLocalizations l) {
    final isSelected = categoryKey.isEmpty
        ? _selectedCategory.isEmpty
        : _selectedCategory == categoryKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CategoryButton(
        icon: icon,
        label: label,
        isSelected: isSelected,
        onTap: () => _filterCategory(categoryKey),
      ),
    );
  }

  void _filterCategory(String category) {
    setState(() {
      if (category.isEmpty || _selectedCategory == category) {
        _selectedCategory = '';
      } else {
        _selectedCategory = category;
      }
    });
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: effectiveTextColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: effectiveTextColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: effectiveTextColor.withAlpha(230),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
