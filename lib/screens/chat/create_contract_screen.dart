import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/rental_item_model.dart';

class CreateContractScreen extends StatefulWidget {
  final String chatId;
  final RentalItemModel? rentalItem; // now optional
  final String otherUserId;

  const CreateContractScreen({
    super.key,
    required this.chatId,
    this.rentalItem,
    required this.otherUserId,
  });

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _startDate;
  DateTime? _endDate;
  final _totalPriceController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();
  final _itemNameController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from rental item if available
    if (widget.rentalItem != null) {
      _itemNameController.text = widget.rentalItem!.itemName;
      _depositController.text = widget.rentalItem!.deposit.toStringAsFixed(0);
      _totalPriceController.text = widget.rentalItem!.dailyRate.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
    _itemNameController.dispose();
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
        // Auto-calculate suggested total price if rental item exists
        if (widget.rentalItem != null) {
          final days = _endDate!.difference(_startDate!).inDays + 1;
          final suggestedPrice = days * widget.rentalItem!.dailyRate;
          _totalPriceController.text = suggestedPrice.toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> _sendContract() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.tr('select_dates'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser!.uid;

      final itemName = _itemNameController.text.trim();

      final contractData = {
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'totalPrice': double.parse(_totalPriceController.text),
        'deposit': double.parse(_depositController.text),
        'rules': _rulesController.text.trim(),
        'rentalItemId': widget.rentalItem?.id ?? '',
        'rentalItemName': itemName,
      };

      final message = ChatMessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: currentUserId,
        message: '📄 ${l.tr('contract_sent_msg')}: $itemName',
        timestamp: DateTime.now(),
        messageType: 'contract',
        contractData: contractData,
        contractStatus: 'pending',
      );

      await FirestoreService().sendMessage(message);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.tr('create_contract')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              Text(l.tr('contract_item_name'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: l.tr('contract_item_hint'),
                  prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l.tr('contract_item_required');
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Date Selector
              Text(l.tr('rental_duration'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateRange(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.primaryTeal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : l.tr('contract_select_dates'),
                          style: TextStyle(
                            color: _startDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Price & Deposit in Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.tr('contract_total_price'), style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _totalPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixText: '฿ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return l.tr('required');
                            if (double.tryParse(val) == null) return l.tr('invalid');
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.tr('contract_deposit'), style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _depositController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixText: '฿ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return l.tr('required');
                            if (double.tryParse(val) == null) return l.tr('invalid');
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rules
              Text(l.tr('contract_rules'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rulesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l.tr('contract_rules_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l.tr('contract_rules_required');
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _sendContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l.tr('contract_send_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
