import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_item_model.dart';
import '../../models/rental_request_model.dart';
import 'package:intl/intl.dart';
import 'request_details_screen.dart';
import 'post_rental_screen.dart';
import 'post_request_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyListingsTab(),
          MyRequestsTab(),
        ],
      ),
    );
  }
}

// My Listings Tab
class MyListingsTab extends StatelessWidget {
  const MyListingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();

    return StreamBuilder<List<RentalItemModel>>(
      stream: firestoreService.getUserRentalItems(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppTheme.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No listings yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post your first item to start earning',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHint,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RentalItemCard(item: item),
            );
          },
        );
      },
    );
  }
}

// My Requests Tab
class MyRequestsTab extends StatelessWidget {
  const MyRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();

    return StreamBuilder<List<RentalRequestModel>>(
      stream: firestoreService.getUserRentalRequests(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppTheme.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No requests yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post a request to find what you need',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHint,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RentalRequestCard(request: request),
            );
          },
        );
      },
    );
  }
}

// Rental Item Card Widget
class RentalItemCard extends StatelessWidget {
  final RentalItemModel item;

  const RentalItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStatusUpdateDialog(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (item.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3, // Use AspectRatio instead of fixed height to avoid aggressive cropping
                child: Image.network(
                  item.imageUrls.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.backgroundColor,
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppTheme.textHint,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name & Category & Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(item.status),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostRentalScreen(itemToEdit: item),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ลบโพสต์'),
                              content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                  child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            try {
                              await FirestoreService().deleteRentalItem(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ลบโพสต์เรียบร้อยแล้ว'),
                                    backgroundColor: AppTheme.secondaryGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('เกิดข้อผิดพลาด: $e'),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('แก้ไขโพสต์'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('ลบโพสต์', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price
                Row(
                  children: [
                    Text(
                      '฿${item.dailyRate}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      ' / day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),

                // Rented Info (if applicable)
                if (item.status == 'rented' && item.rentedToUserName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rented to ${item.rentedToUserName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (item.rentedEndDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Return: ${DateFormat('d MMM yyyy').format(item.rentedEndDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'อัพเดทสถานะสินค้า',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppTheme.secondaryGreen),
                title: const Text('ว่างอยู่ (Available)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'available');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppTheme.error),
                title: const Text('มีคนเช่าอยู่ (Rented)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'rented');
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Colors.grey),
                title: const Text('ซ่อนโพสต์ (Hidden)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'hidden');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    if (item.status == newStatus) return; // No change

    try {
      if (newStatus == 'rented') {
        // Just generic rented if they didn't do it via chat
        await FirestoreService().updateRentalItem(item.id, {
          'status': 'rented',
        });
      } else if (newStatus == 'hidden') {
        await FirestoreService().updateRentalItem(item.id, {
          'status': 'hidden',
        });
      } else {
        await FirestoreService().updateRentalItem(item.id, {
          'status': 'available',
          'rentedToUserId': null,
          'rentedToUserName': null,
        });
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัพเดทสถานะเรียบร้อยแล้ว'),
            backgroundColor: AppTheme.secondaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'available':
        backgroundColor = AppTheme.statusAvailable;
        textColor = Colors.white;
        label = 'Available';
        break;
      case 'pending':
        backgroundColor = AppTheme.statusPending;
        textColor = AppTheme.textPrimary;
        label = 'Request Pending';
        break;
      case 'rented':
        backgroundColor = AppTheme.statusRented;
        textColor = Colors.white;
        label = 'Rented';
        break;
      case 'hidden':
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        label = 'Hidden';
        break;
      default:
        backgroundColor = AppTheme.textHint;
        textColor = Colors.white;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Rental Request Card Widget
class RentalRequestCard extends StatelessWidget {
  final RentalRequestModel request;

  const RentalRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final duration = request.rentalDurationDays;
    final isHidden = request.status == 'hidden';

    return InkWell(
      onTap: () => _showStatusUpdateDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHidden ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Description & Category & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHidden ? Colors.grey.shade200 : AppTheme.primaryTeal.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.search,
                  color: isHidden ? Colors.grey : AppTheme.primaryTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ต้องการเช่าสินค้า: ${request.itemDescription}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isHidden ? AppTheme.textSecondary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isHidden)
                _buildStatusBadge('hidden'),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostRequestScreen(requestToEdit: request),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('ลบประกาศเช่า'),
                        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบประกาศนี้?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('ยกเลิก'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        await FirestoreService().deleteRentalRequest(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลบประกาศเรียบร้อยแล้ว'),
                              backgroundColor: AppTheme.secondaryGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เกิดข้อผิดพลาด: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('แก้ไขประกาศ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('ลบประกาศ', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget
          Row(
            children: [
              Text(
                'Target Budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const Spacer(),
              Text(
                '฿${request.estimatedBudget}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isHidden ? AppTheme.textHint : AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                ' /day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  context,
                  'Start Date',
                  request.startDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateInfo(
                  context,
                  'End Date',
                  request.endDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHidden ? Colors.grey.shade100 : AppTheme.accentMint.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$duration ${duration > 1 ? 'days' : 'day'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHidden ? Colors.grey : null,
                  ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'อัพเดทสถานะประกาศ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppTheme.secondaryGreen),
                title: const Text('กำลังประกาศหาของ (Active)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'active');
                },
              ),
              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.blue),
                title: const Text('ได้ของที่ต้องการแล้ว (Fulfilled)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'fulfilled');
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Colors.grey),
                title: const Text('ซ่อนประกาศ (Hidden)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(context, 'hidden');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    if (request.status == newStatus) return;

    try {
      await FirestoreService().updateRentalRequest(request.id, {
        'status': newStatus,
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัพเดทสถานะเรียบร้อยแล้ว'),
            backgroundColor: AppTheme.secondaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        backgroundColor = AppTheme.statusAvailable;
        textColor = Colors.white;
        label = 'Active';
        break;
      case 'fulfilled':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        label = 'Fulfilled';
        break;
      case 'hidden':
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        label = 'Hidden';
        break;
      default:
        backgroundColor = AppTheme.textHint;
        textColor = Colors.white;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: AppTheme.primaryTeal,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('d MMM').format(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
