import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/rental_item_model.dart';
import '../../models/rental_request_model.dart';

class CreateContractScreen extends StatefulWidget {
  final String chatId;
  final RentalItemModel? rentalItem;
  final RentalRequestModel? rentalRequest;
  final String otherUserId;

  const CreateContractScreen({
    super.key,
    required this.chatId,
    this.rentalItem,
    this.rentalRequest,
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

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    // Pre-fill from rental item if available
    if (widget.rentalItem != null) {
      _itemNameController.text = widget.rentalItem!.itemName;
      _depositController.text = widget.rentalItem!.deposit.toStringAsFixed(0);
      _totalPriceController.text = widget.rentalItem!.dailyRate.toStringAsFixed(0);
    } else if (widget.rentalRequest != null) {
      _itemNameController.text = widget.rentalRequest!.itemDescription;
      _depositController.text = '0'; // Default for requests
      _totalPriceController.text = widget.rentalRequest!.estimatedBudget.toStringAsFixed(0);
      _startDate = widget.rentalRequest!.startDate;
      _endDate = widget.rentalRequest!.endDate;
    }
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
    _itemNameController.dispose();
    _signatureController.dispose();
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

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเซ็นชื่อเพื่อยืนยันสัญญา')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser!.uid;

      // 1. Process Signature
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) throw Exception('ไม่สามารถประมวลผลลายเซ็นได้');
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/owner_sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(signatureBytes);

      final cloudinary = CloudinaryService();
      final signatureUrl = await cloudinary.uploadImage(file, 'contract_signatures');

      // 2. Prepare Contract Message
      final itemName = _itemNameController.text.trim();

      final contractData = {
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'totalPrice': double.parse(_totalPriceController.text),
        'deposit': double.parse(_depositController.text),
        'rules': _rulesController.text.trim(),
        'rentalItemId': widget.rentalItem?.id ?? '',
        'rentalItemName': itemName,
        'ownerSignatureUrl': signatureUrl, // Attach owner signature
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
              const SizedBox(height: 24),

              // Signature Pad
              Text('เซ็นชื่อผู้ให้เช่า (Owner Signature)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Signature(
                        controller: _signatureController,
                        height: 150,
                        backgroundColor: Colors.grey[50]!,
                      ),
                    ),
                    const Divider(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _signatureController.clear(),
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('ล้างลายเซ็น'),
                        ),
                      ],
                    ),
                  ],
                ),
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
