import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/review_model.dart';
import '../../models/rental_contract_model.dart';

class WriteReviewScreen extends StatefulWidget {
  final RentalContractModel contract;

  const WriteReviewScreen({
    super.key,
    required this.contract,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  final List<String> _ownerTags = [
    'Returned on time',
    'Good condition',
    'Great communication',
    'Friendly',
    'Trustworthy',
    'Would rent again',
  ];

  final List<String> _renterTags = [
    'Item as described',
    'Clean & well-maintained',
    'Flexible pickup',
    'Responsive',
    'Fair pricing',
    'Highly recommended',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();
      final currentUserId = authService.currentUser!.uid;
      final currentUser = await firestoreService.getUserData(currentUserId);

      final isOwner = currentUserId == widget.contract.ownerId;

      final review = ReviewModel(
        id: '',
        contractId: widget.contract.id,
        rentalItemId: widget.contract.rentalItemId,
        reviewerId: currentUserId,
        reviewerName: currentUser?.name ?? 'Unknown',
        revieweeId: isOwner ? widget.contract.renterId : widget.contract.ownerId,
        revieweeName: isOwner ? widget.contract.renterName : widget.contract.ownerName,
        reviewType: isOwner ? 'owner_to_renter' : 'renter_to_owner',
        rating: _rating,
        comment: _commentController.text.trim(),
        tags: _selectedTags.toList(),
        createdAt: DateTime.now(),
      );

      await firestoreService.createReview(review);

      // Update reviewee's rating
      await firestoreService.updateUserRating(review.revieweeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop(true);
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;
    final isOwner = currentUserId == widget.contract.ownerId;
    final revieweeName = isOwner ? widget.contract.renterName : widget.contract.ownerName;
    final tags = isOwner ? _ownerTags : _renterTags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Header
            Container(
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryTeal,
                    child: Text(
                      revieweeName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review for',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          revieweeName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOwner ? 'Renter' : 'Owner',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating Section
            Text(
              'Overall Rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRatingSelector(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingLabel(_rating),
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Tags
            Text(
              'Quick Tags (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryTeal,
                  backgroundColor: AppTheme.accentMint.withAlpha(100),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Comment
            Text(
              'Your Review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your experience with ${revieweeName}...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              _rating >= starIndex ? Icons.star : Icons.star_border,
              color: Colors.amber[700],
              size: 48,
            ),
          ),
        );
      }),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5) return 'Excellent! ⭐';
    if (rating >= 4) return 'Great!';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }
}
