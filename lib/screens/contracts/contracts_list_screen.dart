import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_contract_model.dart';
import 'contract_details_screen.dart';

class ContractsListScreen extends StatelessWidget {
  const ContractsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contracts'),
      ),
      body: StreamBuilder<List<RentalContractModel>>(
        stream: FirestoreService().getUserContracts(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final contracts = snapshot.data ?? [];

          if (contracts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contracts yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contracts will appear when rentals are confirmed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHint,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contract = contracts[index];
              return _ContractCard(
                contract: contract,
                currentUserId: currentUserId,
              );
            },
          );
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final RentalContractModel contract;
  final String currentUserId;

  const _ContractCard({
    required this.contract,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = contract.ownerId == currentUserId;
    final otherPartyName = isOwner ? contract.renterName : contract.ownerName;
    final roleLabel = isOwner ? 'Renting to' : 'Renting from';

    return InkWell(
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getStatusColor(contract.status),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(contract.status),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(contract.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${contract.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    contract.itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Other party
                  Row(
                    children: [
                      Text(
                        roleLabel,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        otherPartyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppTheme.primaryTeal),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('d MMM').format(contract.startDate)} - ${DateFormat('d MMM').format(contract.endDate)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '฿${contract.totalAmount}',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // GPS Progress
                  if (contract.status != 'completed') ...[
                    const SizedBox(height: 12),
                    _buildGpsProgress(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsProgress(BuildContext context) {
    final pickupComplete = contract.isPickupComplete;
    final returnComplete = contract.isReturnComplete;

    return Row(
      children: [
        _buildProgressStep(
          'Pickup',
          pickupComplete,
          contract.ownerPickupConfirmed || contract.renterPickupConfirmed,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: pickupComplete ? AppTheme.statusAvailable : AppTheme.divider,
          ),
        ),
        _buildProgressStep(
          'Return',
          returnComplete,
          contract.ownerReturnConfirmed || contract.renterReturnConfirmed,
        ),
      ],
    );
  }

  Widget _buildProgressStep(String label, bool complete, bool inProgress) {
    final color = complete
        ? AppTheme.statusAvailable
        : inProgress
            ? AppTheme.statusPending
            : AppTheme.textHint;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: complete ? color : Colors.white,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: complete
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: complete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.statusPending;
      case 'active':
        return AppTheme.statusRented;
      case 'completed':
        return AppTheme.statusAvailable;
      default:
        return AppTheme.textHint;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'active':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Pickup';
      case 'active':
        return 'Active Rental';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
