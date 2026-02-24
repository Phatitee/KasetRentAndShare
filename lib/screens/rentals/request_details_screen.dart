import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/rental_request_model.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RentalRequestModel request;

  const RequestDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _offerFormKey = GlobalKey<FormState>();
  final _itemDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCondition = 'Like New';
  bool _isSubmittingOffer = false;

  final List<String> _conditions = [
    'Like New',
    'Normal',
    'Used',
  ];

  @override
  void dispose() {
    _itemDescriptionController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!_offerFormKey.currentState!.validate()) return;

    setState(() => _isSubmittingOffer = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get user data for offerer name and rating
      final userData = await firestoreService.getUserData(currentUser.uid);

      final offer = OfferModel(
        id: '',
        requestId: widget.request.id,
        offererId: currentUser.uid,
        offererName: userData?.name ?? 'Unknown',
        offererRating: userData?.rating ?? 0.0,
        itemDescription: _itemDescriptionController.text.trim(),
        pricePerDay: double.parse(_priceController.text),
        condition: _selectedCondition,
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
      );

      await firestoreService.createOffer(offer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );

        // Clear form
        _itemDescriptionController.clear();
        _priceController.clear();
        _messageController.clear();
        setState(() {
          _selectedCondition = 'Like New';
        });
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
        setState(() => _isSubmittingOffer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isRequestOwner = widget.request.requesterId == authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu (edit, delete, etc.)
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Request Details Section
          _buildRequestDetailsSection(),

          const Divider(height: 32, thickness: 8),

          // Offers Section
          _buildOffersSection(isRequestOwner),

          // Offer Form (if not request owner)
          if (!isRequestOwner) ...[
            const Divider(height: 32, thickness: 8),
            _buildOfferForm(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsSection() {
    final duration = widget.request.rentalDurationDays;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          FutureBuilder<UserModel?>(
            future: FirestoreService().getUserData(widget.request.requesterId),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryTeal,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                              user?.name ?? 'Loading...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (user?.isVerified ?? false) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: AppTheme.secondaryGreen,
                              ),
                            ],
                          ],
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.rating.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _getTimeAgo(widget.request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Item Name
          Text(
            widget.request.itemDescription,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 8),

          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentMint.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.request.category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 20),

          // Target Budget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: AppTheme.primaryTeal,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Budget',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '฿${widget.request.estimatedBudget}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            ' /day',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
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
          const SizedBox(height: 16),

          // Rental Period
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Start Date',
                  DateFormat('d MMM').format(widget.request.startDate),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'End Date',
                  DateFormat('d MMM').format(widget.request.endDate),
                  Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration
          _buildInfoCard(
            'Duration',
            '$duration ${duration > 1 ? 'days' : 'day'}',
            Icons.access_time,
          ),
          const SizedBox(height: 20),

          // Additional Details
          if (widget.request.additionalDetails.isNotEmpty) ...[
            Text(
              'Hi everyone! ${widget.request.additionalDetails}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.request.locationName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(bool isRequestOwner) {
    final firestoreService = FirestoreService();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Offers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              StreamBuilder<List<OfferModel>>(
                stream: firestoreService.getRequestOffers(widget.request.id),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Offers List
          StreamBuilder<List<OfferModel>>(
            stream: firestoreService.getRequestOffers(widget.request.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final offers = snapshot.data ?? [];

              if (offers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No offers yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: offers.map((offer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOfferCard(offer, isRequestOwner),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer, bool isRequestOwner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offerer Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.secondaryGreen,
                child: Text(
                  offer.offererName.substring(0, 1).toUpperCase(),
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
                    Text(
                      offer.offererName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          offer.offererRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(offer.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Offer Message
          Text(
            offer.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          // Offer Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OFFER PRICE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '฿${offer.pricePerDay}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                ' /day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusAvailable.withAlpha(51),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  offer.condition,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reply button (for request owner)
          if (isRequestOwner)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to chat
                },
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _offerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Make an offer...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Item Description
            TextFormField(
              controller: _itemDescriptionController,
              decoration: const InputDecoration(
                labelText: 'What you have',
                hintText: 'e.g. Sony A7III + 50mm lens',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your item';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your Price (฿/day)',
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Condition
            Text(
              'Condition',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _conditions.map((condition) {
                final isSelected = _selectedCondition == condition;
                return ChoiceChip(
                  label: Text(condition),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCondition = condition;
                    });
                  },
                  selectedColor: AppTheme.primaryTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Tell more about your item...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please add a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmittingOffer ? null : _submitOffer,
                icon: _isSubmittingOffer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(_isSubmittingOffer ? 'Submitting...' : 'Submit Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
