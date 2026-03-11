import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_contract_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../contracts/contract_details_screen.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen>
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
        title: const Text('ประวัติการเช่า'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'ผู้ให้เช่า (Rented Out)'),
            Tab(text: 'ผู้เช่า (Rented In)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContractListTab(isOwnerTab: true),
          ContractListTab(isOwnerTab: false),
        ],
      ),
    );
  }
}

class ContractListTab extends StatelessWidget {
  final bool isOwnerTab;

  const ContractListTab({super.key, required this.isOwnerTab});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();
    final currentUserId = authService.currentUser!.uid;

    return StreamBuilder<List<RentalContractModel>>(
      stream: firestoreService.getUserContracts(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allContracts = snapshot.data ?? [];
        final filteredContracts = allContracts.where((c) {
          return isOwnerTab ? c.ownerId == currentUserId : c.renterId == currentUserId;
        }).toList();

        if (filteredContracts.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredContracts.length,
          itemBuilder: (context, index) {
            final contract = filteredContracts[index];
            return _ContractHistoryCard(
              contract: contract,
              isOwner: isOwnerTab,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOwnerTab ? Icons.inventory_2_outlined : Icons.shopping_bag_outlined,
            size: 64,
            color: AppTheme.textHint.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการเช่า',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContractHistoryCard extends StatelessWidget {
  final RentalContractModel contract;
  final bool isOwner;

  const _ContractHistoryCard({
    required this.contract,
    required this.isOwner,
  });

  String _getStatusText() {
    if (contract.isReturnComplete) return 'คืนของสำเร็จ';
    if (contract.isPickupComplete) return 'กำลังเช่า';
    return 'รอรับของ';
  }

  Color _getStatusColor() {
    if (contract.isReturnComplete) return AppTheme.success;
    if (contract.isPickupComplete) return AppTheme.primaryTeal;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = isOwner ? contract.renterId : contract.ownerId;
    final otherUserName = isOwner ? contract.renterName : contract.ownerName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailsScreen(contract: contract),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.divider.withAlpha(50)),
        ),
        child: Column(
          children: [
            // Top Row: Status & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(contract.createdAt),
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle Row: Item Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Image Placeholder
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOwner ? Icons.outbox : Icons.move_to_inbox,
                    color: AppTheme.primaryTeal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.itemName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ระยะเวลา: ${DateFormat('d MMM').format(contract.startDate)} - ${DateFormat('d MMM').format(contract.endDate)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'รวม ${contract.rentalDays} วัน',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${contract.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (contract.deposit > 0)
                      Text(
                        'มัดจำ ฿${contract.deposit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Bottom Row: Other Party Info
            FutureBuilder<UserModel?>(
              future: FirestoreService().getUserData(otherUserId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Row(
                  children: [
                    UserAvatar(
                      photoUrl: user?.photoUrl,
                      name: otherUserName,
                      radius: 14,
                      fontSize: 10,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOwner ? 'ผู้เช่า: ' : 'ผู้ให้เช่า: ',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      otherUserName,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.textHint,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
