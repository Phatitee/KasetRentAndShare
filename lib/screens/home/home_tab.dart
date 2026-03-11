import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
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

  // Advanced Filters
  double? _minPrice;
  double? _maxPrice;
  String? _filterCondition;
  bool _showOnlyItems = false;
  bool _showOnlyRequests = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ตัวกรอง (Filters)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _minPrice = null;
                            _maxPrice = null;
                            _filterCondition = null;
                            _showOnlyItems = false;
                            _showOnlyRequests = false;
                          });
                        },
                        child: Text(
                          'ล้างค่า',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Post Type
                  const Text('ประเภทโพสต์', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('เฉพาะสินค้าเช่า'),
                        selected: _showOnlyItems,
                        onSelected: (val) {
                          setModalState(() {
                            _showOnlyItems = val;
                            if (val) _showOnlyRequests = false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('เฉพาะหาของเช่า'),
                        selected: _showOnlyRequests,
                        onSelected: (val) {
                          setModalState(() {
                            _showOnlyRequests = val;
                            if (val) _showOnlyItems = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Range
                  const Text('ช่วงราคา (บาท/วัน)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'ขั้นต่ำ',
                            prefixText: '฿',
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => _minPrice = double.tryParse(val),
                          controller: TextEditingController(text: _minPrice?.toString() ?? ''),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('-')),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'สูงสุด',
                            prefixText: '฿',
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => _maxPrice = double.tryParse(val),
                          controller: TextEditingController(text: _maxPrice?.toString() ?? ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Condition
                  const Text('สภาพสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Like New (95%+)', 'Good', 'Fair'].map((cond) {
                      final isSelected = _filterCondition == cond;
                      return ChoiceChip(
                        label: Text(cond),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() => _filterCondition = selected ? cond : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Refresh HomeTab with new filters
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                      child: const Text('ใช้ตัวกรอง'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasActiveFilters = _minPrice != null || _maxPrice != null || _filterCondition != null || _showOnlyItems || _showOnlyRequests;

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
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: hasActiveFilters ? AppTheme.primaryTeal.withAlpha(30) : AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: hasActiveFilters ? AppTheme.primaryTeal : AppTheme.textPrimary,
                            ),
                            onPressed: _showFilterBottomSheet,
                          ),
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
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
            List<FeedItem> feedItems = [];

            final items = itemsSnapshot.data ?? [];
            if (!_showOnlyRequests) {
              for (final item in items) {
                feedItems.add(FeedItem.fromRentalItem(item));
              }
            }

            final requests = requestsSnapshot.data ?? [];
            if (!_showOnlyItems) {
              for (final request in requests) {
                feedItems.add(FeedItem.fromRentalRequest(request));
              }
            }

            // Apply Advanced Filters
            feedItems = feedItems.where((fi) {
              // 1. Keyword Search
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                if (fi.isRentalItem) {
                  final matches = fi.rentalItem!.itemName.toLowerCase().contains(query) ||
                      fi.rentalItem!.description.toLowerCase().contains(query);
                  if (!matches) return false;
                } else {
                  final matches = fi.rentalRequest!.itemDescription.toLowerCase().contains(query);
                  if (!matches) return false;
                }
              }

              // 2. Price Filter
              final price = fi.isRentalItem ? fi.rentalItem!.dailyRate : fi.rentalRequest!.estimatedBudget;
              if (_minPrice != null && price < _minPrice!) return false;
              if (_maxPrice != null && price > _maxPrice!) return false;

              // 3. Condition Filter (Only for items)
              if (_filterCondition != null) {
                if (fi.isRequest) return false;
                if (fi.rentalItem!.condition != _filterCondition) return false;
              }

              return true;
            }).toList();

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
                        child: FutureBuilder<UserModel?>(
                          future: _firestoreService.getUser(item.ownerId),
                          builder: (context, userSnapshot) {
                            final ownerName = userSnapshot.data?.name ?? AppLocalizations.of(context).tr('owner');
                            final ownerPhotoUrl = userSnapshot.data?.photoUrl;
                            final ownerRating = userSnapshot.data?.rating ?? 0.0;
                            
                            return ListingCard(
                              imageUrl: item.imageUrls.isNotEmpty
                                  ? item.imageUrls.first
                                  : null,
                              itemName: item.itemName,
                              pricePerDay: item.dailyRate,
                              ownerName: ownerName,
                              ownerPhotoUrl: ownerPhotoUrl,
                              ownerRating: ownerRating,
                              isVerified: userSnapshot.data?.isVerified ?? false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      final request = feedItem.rentalRequest!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RequestCard(
                          request: request,
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
