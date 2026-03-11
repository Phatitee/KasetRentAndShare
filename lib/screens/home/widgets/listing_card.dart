import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../widgets/user_avatar.dart';

class ListingCard extends StatelessWidget {
  final String? imageUrl;
  final String itemName;
  final double pricePerDay;
  final String ownerName;
  final String? ownerPhotoUrl;
  final double ownerRating;
  final bool isVerified;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    this.imageUrl,
    required this.itemName,
    required this.pricePerDay,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.ownerRating,
    this.isVerified = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.0,  // Changed from 16/9 to square to prevent bad cropping
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      Text(
                        '฿$pricePerDay',
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
                  const SizedBox(height: 12),

                  // Owner Info
                  Row(
                    children: [
                      UserAvatar(
                        photoUrl: ownerPhotoUrl,
                        name: ownerName,
                        radius: 12,
                        fontSize: 10,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ownerName,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppTheme.secondaryGreen,
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ownerRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: AppTheme.textHint,
      ),
    );
  }
}
