import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
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

  @override
  Widget build(BuildContext context) {
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
                      'Kaset RentShare',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Safe rentals for KU students',
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
                  decoration: InputDecoration(
                    hintText: 'Find cameras, textbooks...',
                    prefixIcon: const Icon(Icons.search),
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
                        title: 'Post Item',
                        subtitle: 'Earn from your gear',
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
                        title: 'Request',
                        subtitle: 'Find what you need',
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
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CategoryButton(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          isSelected: _selectedCategory == 'Camera',
                          onTap: () => _filterCategory('Camera'),
                        ),
                        CategoryButton(
                          icon: Icons.laptop,
                          label: 'Electronics',
                          isSelected: _selectedCategory == 'Electronics',
                          onTap: () => _filterCategory('Electronics'),
                        ),
                        CategoryButton(
                          icon: Icons.checkroom,
                          label: 'Fashion',
                          isSelected: _selectedCategory == 'Fashion',
                          onTap: () => _filterCategory('Fashion'),
                        ),
                        CategoryButton(
                          icon: Icons.menu_book,
                          label: 'Books',
                          isSelected: _selectedCategory == 'Books',
                          onTap: () => _filterCategory('Books'),
                        ),
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
                      _selectedCategory.isEmpty ? 'Feed' : _selectedCategory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_selectedCategory.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = '');
                        },
                        child: Text(
                          'Clear Filter',
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
                          'No posts yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to post or request an item!',
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

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feedItem = feedItems[index];

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
                          ownerName: 'Owner',
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
                          requesterName: 'Requester',
                          onTap: () {
                            // TODO: Navigate to request detail
                          },
                        ),
                      );
                    }
                  },
                  childCount: feedItems.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _filterCategory(String category) {
    setState(() {
      _selectedCategory =
          _selectedCategory == category ? '' : category;
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
