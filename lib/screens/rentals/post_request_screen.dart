import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../models/rental_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:provider/provider.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemDescriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  String _selectedCategory = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _locationName = '';
  GeoPoint? _pickupLocation;
  bool _isLoading = false;

  final List<String> _categories = [
    'Camera',
    'Electronics',
    'Fashion',
    'Books',
    'Sports',
    'Music',
    'Others',
  ];

  @override
  void dispose() {
    _itemDescriptionController.dispose();
    _budgetController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _selectLocation() {
    // TODO: Implement Google Maps location picker
    // For now, set default to Kasetsart University
    setState(() {
      _locationName = 'Kasetsart University, Bang Khen';
      _pickupLocation = const GeoPoint(13.8462, 100.5713);
    });

    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.tr('location_set')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitRequest() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('select_category_required'))),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('select_dates'))),
      );
      return;
    }

    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('set_location_required'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();

      final request = RentalRequestModel(
        id: '',
        requesterId: authService.currentUser!.uid,
        itemDescription: _itemDescriptionController.text.trim(),
        category: _selectedCategory,
        startDate: _startDate!,
        endDate: _endDate!,
        estimatedBudget: double.parse(_budgetController.text),
        pickupLocation: _pickupLocation!,
        locationName: _locationName,
        additionalDetails: _additionalDetailsController.text.trim(),
        createdAt: DateTime.now(),
      );

      await firestoreService.createRentalRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr('request_posted')),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.tr('error')}: $e'),
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('post_request_appbar')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // What are you looking for?
            Text(
              l.tr('what_looking_for'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemDescriptionController,
              decoration: InputDecoration(
                hintText: l.tr('what_looking_hint'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.tr('describe_need');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Category
            Text(
              l.tr('category'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.primaryTeal,
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : '';
                    });
                  },
                  selectedColor: AppTheme.primaryTeal,
                  backgroundColor: AppTheme.accentMint.withAlpha(100),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Rental Duration
            Text(
              l.tr('rental_duration'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: l.tr('start_date'),
                    date: _startDate,
                    onTap: _selectDateRange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    label: l.tr('end_date'),
                    date: _endDate,
                    onTap: _selectDateRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Estimated Budget
            Text(
              l.tr('estimated_budget'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.currency_exchange,
                  color: AppTheme.primaryTeal,
                ),
                helperText: l.tr('budget_per_day'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.tr('enter_budget');
                }
                if (double.tryParse(value) == null) {
                  return l.tr('invalid_number');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Pick-up Location
            Text(
              l.tr('pickup_location'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectLocation,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: _pickupLocation == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 48,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.tr('set_location'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryTeal,
                                ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 48,
                                  color: AppTheme.primaryTeal,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    _locationName,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryTeal,
                              radius: 16,
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_locationName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _locationName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Additional Details
            Text(
              l.tr('additional_details'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _additionalDetailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l.tr('additional_details_hint'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l.tr('post_btn')),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? DateFormat('d MMM').format(date)
                  : 'Select',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: date != null ? AppTheme.textPrimary : AppTheme.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Camera':
        return Icons.camera_alt;
      case 'Electronics':
        return Icons.laptop;
      case 'Fashion':
        return Icons.checkroom;
      case 'Books':
        return Icons.menu_book;
      case 'Sports':
        return Icons.sports_basketball;
      case 'Music':
        return Icons.music_note;
      default:
        return Icons.category;
    }
  }
}
