import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_item_model.dart';
import '../../models/user_model.dart';
import '../../models/chat_message_model.dart';
import '../chat/chat_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final RentalItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _owner;
  bool _loadingOwner = true;
  int _currentImageIndex = 0;
  bool _requestingRental = false;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final owner = await _firestoreService.getUserData(widget.item.ownerId);
    if (mounted) {
      setState(() {
        _owner = owner;
        _loadingOwner = false;
      });
    }
  }

  /// Extract first name from KU email (e.g. chaimongkhon.na@ku.th → Chaimongkhon)
  String _getFirstName(String? email, String? fallbackName) {
    if (email != null && email.isNotEmpty) {
      final local = email.split('@').first;
      final first = local.split('.').first;
      if (first.isNotEmpty) {
        return first[0].toUpperCase() + first.substring(1);
      }
    }
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return fallbackName.split(' ').first;
    }
    return 'Owner';
  }

  Future<void> _requestRental() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    // Cannot rent your own item
    if (widget.item.ownerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่สามารถเช่าสิ่งของของตัวเองได้')),
      );
      return;
    }

    setState(() => _requestingRental = true);

    try {
      final ownerName =
          _getFirstName(_owner?.email, _owner?.name);

      // Get or create chat between current user and owner
      final chatId = await _firestoreService.getOrCreateChat(
        currentUser.uid,
        widget.item.ownerId,
        rentalItemId: widget.item.id,
        rentalItemName: widget.item.itemName,
      );

      // Send item card message
      await _firestoreService.sendMessage(
        ChatMessageModel(
          id: '',
          chatId: chatId,
          senderId: currentUser.uid,
          message: '🛍️ ขอเช่า: ${widget.item.itemName}',
          timestamp: DateTime.now(),
          messageType: 'item_card',
          itemId: widget.item.id,
          itemName: widget.item.itemName,
          itemImageUrl: widget.item.imageUrls.isNotEmpty
              ? widget.item.imageUrls.first
              : null,
          itemPrice: widget.item.dailyRate,
        ),
      );

      // Send automatic rental inquiry text message right after
      final inquiryMsg = '🛍️ สวัสดีครับ/ค่ะ! สนใจเช่า "${widget.item.itemName}"\n'
          'ในราคา ฿${widget.item.dailyRate.toStringAsFixed(0)}/วัน\n'
          'ขอทราบรายละเอียดเพิ่มเติมหน่อยครับ/ค่ะ 😊';

      await _firestoreService.sendMessage(
        ChatMessageModel(
          id: '',
          chatId: chatId,
          senderId: currentUser.uid,
          message: inquiryMsg,
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
          messageType: 'text',
        ),
      );

      if (mounted) {
        // Navigate to chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: widget.item.ownerId,
              otherUserName: ownerName,
              rentalItemId: widget.item.id,
              rentalItemName: widget.item.itemName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingRental = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwner = authService.currentUser?.uid == item.ownerId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(child: _buildImageCarousel(item)),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name + Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '฿${item.dailyRate.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'per day',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Badges: Condition + Deposit
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            icon: Icons.star_outline,
                            label: 'Condition: ${item.condition}',
                            color: AppTheme.accentMint,
                            textColor: AppTheme.primaryTeal,
                          ),
                          _buildBadge(
                            icon: Icons.shield_outlined,
                            label:
                                'Deposit: ฿${item.deposit.toStringAsFixed(0)}',
                            color: Colors.amber.shade50,
                            textColor: Colors.orange.shade800,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Owner Info
                      _buildOwnerRow(item),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'No description provided.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Category chip
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(item.category),
                            backgroundColor:
                                AppTheme.primaryTeal.withOpacity(0.1),
                            labelStyle:
                                TextStyle(color: AppTheme.primaryTeal),
                            side: BorderSide.none,
                          ),
                          _buildStatusChip(item.status),
                        ],
                      ),
                      // Bottom padding for the bottom bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Top nav bar (back + share)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navButton(
                      Icons.arrow_back,
                      () => Navigator.pop(context),
                    ),
                    _navButton(Icons.share_outlined, () {}),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar: Total + Request Rental
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(item, isOwner),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(RentalItemModel item) {
    if (item.imageUrls.isEmpty) {
      return Container(
        height: 280,
        color: AppTheme.backgroundColor,
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppTheme.textHint,
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: item.imageUrls.length,
            onPageChanged: (i) =>
                setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: item.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppTheme.backgroundColor,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.backgroundColor,
                  child: Icon(Icons.image_outlined,
                      size: 64, color: AppTheme.textHint),
                ),
              );
            },
          ),
          if (item.imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  item.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImageIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == i
                          ? AppTheme.primaryTeal
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerRow(RentalItemModel item) {
    if (_loadingOwner) {
      return const Center(child: CircularProgressIndicator());
    }
    final ownerName = _getFirstName(_owner?.email, _owner?.name);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isOwner = authService.currentUser?.uid == item.ownerId;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryTeal,
          foregroundImage: _owner?.photoUrl != null
              ? NetworkImage(_owner!.photoUrl!)
              : null,
          child: Text(
            ownerName.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ownerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  if (_owner?.isVerified == true)
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 16, color: AppTheme.secondaryGreen),
                        const SizedBox(width: 2),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 2),
                  Text(
                    '${(_owner?.rating ?? 0.0).toStringAsFixed(1)} (${_owner?.totalReviews ?? 0} reviews)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Chat icon (if not owner)
        if (!isOwner)
          IconButton(
            onPressed: _requestingRental ? null : _requestRental,
            icon: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryTeal),
            tooltip: 'Chat with owner',
          ),
      ],
    );
  }

  Widget _buildBottomBar(RentalItemModel item, bool isOwner) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total for 1 day',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                '฿${item.dailyRate.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isOwner
                ? OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Your Listing'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.primaryTeal),
                      foregroundColor: AppTheme.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _requestingRental
                        ? null
                        : (item.status == 'available'
                            ? _requestRental
                            : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.status == 'available'
                          ? AppTheme.primaryTeal
                          : AppTheme.textHint,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _requestingRental
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            item.status == 'available'
                                ? 'Request Rental'
                                : 'Not Available',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'available':
        bg = AppTheme.statusAvailable;
        label = 'Available';
        break;
      case 'rented':
        bg = AppTheme.statusRented;
        label = 'Rented';
        break;
      default:
        bg = AppTheme.statusPending;
        label = 'Pending';
    }
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: bg,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
