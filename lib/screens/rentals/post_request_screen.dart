import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/rental_request_model.dart';

class PostRequestScreen extends StatefulWidget {
  final RentalRequestModel? requestToEdit;

  const PostRequestScreen({super.key, this.requestToEdit});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  String _selectedCategory = 'Electronics';
  DateTime? _startDate;
  DateTime? _endDate;
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
  void initState() {
    super.initState();
    if (widget.requestToEdit != null) {
      final req = widget.requestToEdit!;
      _descriptionController.text = req.itemDescription;
      _budgetController.text = req.estimatedBudget.toString();
      _additionalDetailsController.text = req.additionalDetails;
      _selectedCategory = req.category;
      _startDate = req.startDate;
      _endDate = req.endDate;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
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

  void _showCategoryPicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.tr('select_category'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._categories.map((category) => ListTile(
                    title: Text(category),
                    trailing: _selectedCategory == category
                        ? const Icon(Icons.check, color: AppTheme.primaryTeal)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('select_dates'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = FirestoreService();
      final currentUserId = authService.currentUser!.uid;

      if (widget.requestToEdit != null) {
        // Update existing request
        final updatedData = {
          'category': _selectedCategory,
          'itemDescription': _descriptionController.text.trim(),
          'estimatedBudget': double.parse(_budgetController.text),
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'additionalDetails': _additionalDetailsController.text.trim(),
        };

        await firestoreService.updateRentalRequest(
          widget.requestToEdit!.id,
          updatedData,
        );
      } else {
        // Create new request
        final request = RentalRequestModel(
          id: '',
          requesterId: currentUserId,
          category: _selectedCategory,
          itemDescription: _descriptionController.text.trim(),
          estimatedBudget: double.parse(_budgetController.text),
          startDate: _startDate!,
          endDate: _endDate!,
          additionalDetails: _additionalDetailsController.text.trim(),
          createdAt: DateTime.now(),
        );

        await firestoreService.createRentalRequest(request);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr('request_posted')),
            backgroundColor: AppTheme.success,
          ),
        );
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
        title: Text(widget.requestToEdit != null
            ? 'แก้ไขคำขอเช่า'
            : l.tr('post_request_appbar')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMint.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l.tr('what_looking_for'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Item Name / Description
                  Text(
                    l.tr('what_looking_for'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: l.tr('what_looking_hint'),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? l.tr('required')
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Category
                  Text(
                    l.tr('category'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory.isEmpty
                                ? l.tr('select_category')
                                : _selectedCategory,
                            style: TextStyle(
                              color: _selectedCategory.isEmpty
                                  ? AppTheme.textHint
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
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
                      prefixText: '฿ ',
                      prefixStyle: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return l.tr('required');
                      if (double.tryParse(val) == null) return l.tr('invalid_number');
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date Range
                  Text(
                    l.tr('rental_duration'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: AppTheme.primaryTeal, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                : l.tr('select_dates'),
                            style: TextStyle(
                              color: _startDate != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: Text(
                        widget.requestToEdit != null
                            ? l.tr('save')
                            : l.tr('post_btn'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
