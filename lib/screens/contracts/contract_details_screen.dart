import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_contract_model.dart';

class ContractDetailsScreen extends StatefulWidget {
  final RentalContractModel contract;

  const ContractDetailsScreen({
    super.key,
    required this.contract,
  });

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  late RentalContractModel _contract;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _confirmPickup(bool isOwner) async {
    setState(() => _isLoading = true);

    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firestoreService = FirestoreService();
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      Map<String, dynamic> updateData = {
        'pickupLocation': geoPoint,
        'pickupLocationName': 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}',
      };

      if (isOwner) {
        updateData['ownerPickupConfirmed'] = true;
      } else {
        updateData['renterPickupConfirmed'] = true;
      }

      // Check if both confirmed
      if ((isOwner && _contract.renterPickupConfirmed) ||
          (!isOwner && _contract.ownerPickupConfirmed)) {
        updateData['pickupConfirmedAt'] = Timestamp.now();
        updateData['status'] = 'active';
      }

      await firestoreService.updateContract(_contract.id, updateData);

      // Update local state
      setState(() {
        _contract = _contract.copyWith(
          pickupLocation: geoPoint,
          ownerPickupConfirmed: isOwner ? true : _contract.ownerPickupConfirmed,
          renterPickupConfirmed: !isOwner ? true : _contract.renterPickupConfirmed,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup confirmed with GPS location!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmReturn(bool isOwner) async {
    setState(() => _isLoading = true);

    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firestoreService = FirestoreService();
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      Map<String, dynamic> updateData = {
        'returnLocation': geoPoint,
        'returnLocationName': 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}',
      };

      if (isOwner) {
        updateData['ownerReturnConfirmed'] = true;
      } else {
        updateData['renterReturnConfirmed'] = true;
      }

      // Check if both confirmed
      if ((isOwner && _contract.renterReturnConfirmed) ||
          (!isOwner && _contract.ownerReturnConfirmed)) {
        updateData['returnConfirmedAt'] = Timestamp.now();
        updateData['status'] = 'completed';
      }

      await firestoreService.updateContract(_contract.id, updateData);

      // Update local state
      setState(() {
        _contract = _contract.copyWith(
          returnLocation: geoPoint,
          ownerReturnConfirmed: isOwner ? true : _contract.ownerReturnConfirmed,
          renterReturnConfirmed: !isOwner ? true : _contract.renterReturnConfirmed,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return confirmed with GPS location!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;
    final isOwner = currentUserId == _contract.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Contract'),
        actions: [
          // TODO: Add PDF export button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Banner
                _buildStatusBanner(),
                const SizedBox(height: 20),

                // Contract Info
                _buildContractInfo(),
                const SizedBox(height: 20),

                // Parties
                _buildPartiesSection(),
                const SizedBox(height: 20),

                // Item Details
                _buildItemDetails(),
                const SizedBox(height: 20),

                // Financial Summary
                _buildFinancialSummary(),
                const SizedBox(height: 20),

                // GPS Tracking Section
                _buildGpsTrackingSection(isOwner),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    String statusText;
    IconData icon;

    switch (_contract.status) {
      case 'pending':
        backgroundColor = AppTheme.statusPending;
        statusText = 'Pending Pickup';
        icon = Icons.pending;
        break;
      case 'active':
        backgroundColor = AppTheme.statusRented;
        statusText = 'Active Rental';
        icon = Icons.check_circle;
        break;
      case 'completed':
        backgroundColor = AppTheme.statusAvailable;
        statusText = 'Completed';
        icon = Icons.done_all;
        break;
      default:
        backgroundColor = AppTheme.textHint;
        statusText = _contract.status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Contract #${_contract.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfo() {
    return _buildCard(
      title: 'Rental Period',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Start Date',
                  DateFormat('d MMM yyyy').format(_contract.startDate),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'End Date',
                  DateFormat('d MMM yyyy').format(_contract.endDate),
                  Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentMint.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_contract.rentalDays} days rental',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesSection() {
    return _buildCard(
      title: 'Parties',
      child: Column(
        children: [
          _buildPartyRow('Owner', _contract.ownerName, Icons.person),
          const Divider(height: 24),
          _buildPartyRow('Renter', _contract.renterName, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildPartyRow(String role, String name, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.primaryTeal,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetails() {
    return _buildCard(
      title: 'Item Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contract.itemName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Condition: '),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _contract.condition,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_contract.ownerNotes != null && _contract.ownerNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes: ${_contract.ownerNotes}',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return _buildCard(
      title: 'Financial Summary',
      child: Column(
        children: [
          _buildFinancialRow('Daily Rate', '฿${_contract.dailyRate}'),
          const SizedBox(height: 8),
          _buildFinancialRow('Duration', '${_contract.rentalDays} days'),
          const Divider(height: 16),
          _buildFinancialRow(
            'Total Amount',
            '฿${_contract.totalAmount}',
            isTotal: true,
          ),
          const SizedBox(height: 8),
          _buildFinancialRow('Deposit', '฿${_contract.deposit}'),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.primaryTeal : AppTheme.textPrimary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsTrackingSection(bool isOwner) {
    return _buildCard(
      title: 'GPS Tracking',
      child: Column(
        children: [
          // Pickup Section
          _buildGpsConfirmationRow(
            title: '📍 Pickup Confirmation',
            ownerConfirmed: _contract.ownerPickupConfirmed,
            renterConfirmed: _contract.renterPickupConfirmed,
            location: _contract.pickupLocationName,
            confirmedAt: _contract.pickupConfirmedAt,
            onConfirm: _contract.isPickupComplete
                ? null
                : () => _confirmPickup(isOwner),
            isOwner: isOwner,
            alreadyConfirmed: isOwner
                ? _contract.ownerPickupConfirmed
                : _contract.renterPickupConfirmed,
          ),

          const Divider(height: 32),

          // Return Section
          _buildGpsConfirmationRow(
            title: '📍 Return Confirmation',
            ownerConfirmed: _contract.ownerReturnConfirmed,
            renterConfirmed: _contract.renterReturnConfirmed,
            location: _contract.returnLocationName,
            confirmedAt: _contract.returnConfirmedAt,
            onConfirm: !_contract.isPickupComplete || _contract.isReturnComplete
                ? null
                : () => _confirmReturn(isOwner),
            isOwner: isOwner,
            alreadyConfirmed: isOwner
                ? _contract.ownerReturnConfirmed
                : _contract.renterReturnConfirmed,
            isReturn: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGpsConfirmationRow({
    required String title,
    required bool ownerConfirmed,
    required bool renterConfirmed,
    String? location,
    DateTime? confirmedAt,
    VoidCallback? onConfirm,
    required bool isOwner,
    required bool alreadyConfirmed,
    bool isReturn = false,
  }) {
    final bothConfirmed = ownerConfirmed && renterConfirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Confirmation status
        Row(
          children: [
            _buildConfirmationChip('Owner', ownerConfirmed),
            const SizedBox(width: 8),
            _buildConfirmationChip('Renter', renterConfirmed),
          ],
        ),

        // Location info
        if (location != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.primaryTeal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Timestamp
        if (confirmedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Completed: ${DateFormat('d MMM yyyy, HH:mm').format(confirmedAt)}',
            style: TextStyle(
              color: AppTheme.statusAvailable,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Confirm button
        if (!bothConfirmed && onConfirm != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alreadyConfirmed ? null : onConfirm,
              icon: const Icon(Icons.gps_fixed, size: 20),
              label: Text(
                alreadyConfirmed
                    ? 'Waiting for ${isOwner ? "renter" : "owner"}'
                    : 'Confirm with GPS',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    alreadyConfirmed ? AppTheme.textHint : AppTheme.primaryTeal,
              ),
            ),
          ),
        ],

        // Disabled message for return before pickup
        if (isReturn && !_contract.isPickupComplete) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete pickup confirmation first',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmationChip(String label, bool confirmed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: confirmed ? AppTheme.statusAvailable : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: confirmed ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: confirmed ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryTeal,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryTeal),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
