import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_item_model.dart';
import '../../models/rental_request_model.dart';
import 'package:intl/intl.dart';
import 'post_rental_screen.dart';
import 'post_request_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('my_posts_title')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: l.tr('my_listings_tab')),
            Tab(text: l.tr('my_requests_tab')),
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

class MyListingsTab extends StatelessWidget {
  const MyListingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();

    return StreamBuilder<List<RentalItemModel>>(
      stream: firestoreService.getUserRentalItems(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l.tr('error')}: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text(l.tr('no_listings_yet'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RentalItemCard(item: items[index]),
          ),
        );
      },
    );
  }
}

class MyRequestsTab extends StatelessWidget {
  const MyRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();

    return StreamBuilder<List<RentalRequestModel>>(
      stream: firestoreService.getUserRentalRequests(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l.tr('error')}: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text(l.tr('no_requests_yet'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RentalRequestCard(request: requests[index]),
          ),
        );
      },
    );
  }
}

class RentalItemCard extends StatelessWidget {
  final RentalItemModel item;
  const RentalItemCard({super.key, required this.item});

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final l = AppLocalizations.of(context);
    if (item.status == newStatus) return;
    try {
      final updates = <String, dynamic>{'status': newStatus};
      if (newStatus == 'available') {
        updates['rentedToUserId'] = null;
        updates['rentedToUserName'] = null;
      }
      await FirestoreService().updateRentalItem(item.id, updates);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tr('status_updated_msg')), backgroundColor: AppTheme.secondaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostRentalScreen(itemToEdit: item))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(item.imageUrls.first, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(item.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context),
                      _buildMenuButton(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('฿${item.dailyRate} / ${AppLocalizations.of(context).tr('day')}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color bg;
    String label;
    switch (item.status) {
      case 'available': bg = AppTheme.statusAvailable; label = l.tr('status_available'); break;
      case 'rented': bg = AppTheme.statusRented; label = l.tr('status_rented'); break;
      case 'hidden': bg = Colors.grey; label = l.tr('status_hidden'); break;
      default: bg = AppTheme.textHint; label = item.status;
    }

    return PopupMenuButton<String>(
      onSelected: (val) => _updateStatus(context, val),
      offset: const Offset(0, 40),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'available', child: Text(l.tr('status_available'))),
        PopupMenuItem(value: 'rented', child: Text(l.tr('status_rented'))),
        PopupMenuItem(value: 'hidden', child: Text(l.tr('status_hidden'))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
      onSelected: (val) async {
        if (val == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PostRentalScreen(itemToEdit: item)));
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.tr('delete_confirm_title')),
              content: Text(l.tr('delete_confirm_msg')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.tr('cancel'))),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: Text(l.tr('delete'))),
              ],
            ),
          );
          if (confirm == true) {
            await FirestoreService().deleteRentalItem(item.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.tr('post_deleted_msg')), backgroundColor: AppTheme.secondaryGreen),
              );
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'edit', child: Text(l.tr('edit_post'))),
        PopupMenuItem(value: 'delete', child: Text(l.tr('delete_post'), style: const TextStyle(color: Colors.red))),
      ],
    );
  }
}

class RentalRequestCard extends StatelessWidget {
  final RentalRequestModel request;
  const RentalRequestCard({super.key, required this.request});

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final l = AppLocalizations.of(context);
    if (request.status == newStatus) return;
    try {
      await FirestoreService().updateRentalRequest(request.id, {'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tr('status_updated_msg')), backgroundColor: AppTheme.secondaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isHidden = request.status == 'hidden';
    return Container(
      decoration: BoxDecoration(
        color: isHidden ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostRequestScreen(requestToEdit: request))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isHidden ? Colors.grey.shade200 : AppTheme.primaryTeal.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                    child: Icon(isHidden ? Icons.visibility_off_outlined : Icons.search, color: isHidden ? Colors.grey : AppTheme.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l.tr('want_to_rent_label')} ${request.itemDescription}', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(request.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                  _buildMenuButton(context),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.tr('target_budget_label'), style: Theme.of(context).textTheme.bodySmall),
                  Text('฿${request.estimatedBudget} / ${l.tr('day')}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color bg;
    String label;
    switch (request.status) {
      case 'active': bg = AppTheme.statusAvailable; label = l.tr('status_active'); break;
      case 'fulfilled': bg = Colors.blue; label = l.tr('status_fulfilled'); break;
      case 'hidden': bg = Colors.grey; label = l.tr('status_hidden'); break;
      default: bg = AppTheme.textHint; label = request.status;
    }

    return PopupMenuButton<String>(
      onSelected: (val) => _updateStatus(context, val),
      offset: const Offset(0, 40),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'active', child: Text(l.tr('status_active'))),
        PopupMenuItem(value: 'fulfilled', child: Text(l.tr('status_fulfilled'))),
        PopupMenuItem(value: 'hidden', child: Text(l.tr('status_hidden'))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
      onSelected: (val) async {
        if (val == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PostRequestScreen(requestToEdit: request)));
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.tr('delete_confirm_title')),
              content: Text(l.tr('delete_confirm_msg')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.tr('cancel'))),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: Text(l.tr('delete'))),
              ],
            ),
          );
          if (confirm == true) {
            await FirestoreService().deleteRentalRequest(request.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.tr('post_deleted_msg')), backgroundColor: AppTheme.secondaryGreen),
              );
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'edit', child: Text(l.tr('edit_post'))),
        PopupMenuItem(value: 'delete', child: Text(l.tr('delete_post'), style: const TextStyle(color: Colors.red))),
      ],
    );
  }
}
