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
    'Electronics',
    'Tools',
    'Books',
    'Sports',
    'Clothing',
    'Other',
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
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryTeal,
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
            content: Text(widget.requestToEdit != null
                ? l.tr('request_updated')
                : l.tr('request_posted')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.requestToEdit != null
            ? l.tr('edit_request')
            : l.tr('post_request')),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Description
                    Text(l.tr('what_do_you_need'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l.tr('request_description_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.search, color: AppTheme.primaryTeal),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? l.tr('field_required')
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Category
                    Text(l.tr('category'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Estimated Budget
                    Text(l.tr('estimated_budget'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '฿ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return l.tr('field_required');
                        if (double.tryParse(val) == null) return l.tr('invalid_number');
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Date Range
                    Text(l.tr('rental_period'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: AppTheme.primaryTeal, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                  : l.tr('select_date_range'),
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
                    Text(l.tr('additional_details'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _additionalDetailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l.tr('additional_details_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.requestToEdit != null
                              ? l.tr('update_request')
                              : l.tr('post_request'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
