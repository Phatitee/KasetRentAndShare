import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/rental_item_model.dart';

class CreateContractScreen extends StatefulWidget {
  final String chatId;
  final RentalItemModel rentalItem;
  final String otherUserId;

  const CreateContractScreen({
    super.key,
    required this.chatId,
    required this.rentalItem,
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

  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill some defaults
    _depositController.text = widget.rentalItem.deposit.toStringAsFixed(0);
    _totalPriceController.text = widget.rentalItem.dailyRate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
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
        // Auto-calculate suggested total price
        final days = _endDate!.difference(_startDate!).inDays + 1; // inclusive
        final suggestedPrice = days * widget.rentalItem.dailyRate;
        _totalPriceController.text = suggestedPrice.toStringAsFixed(0);
      });
    }
  }

  Future<void> _sendContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกช่วงเวลาเช่า')),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser!.uid;

      final contractData = {
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'totalPrice': double.parse(_totalPriceController.text),
        'deposit': double.parse(_depositController.text),
        'rules': _rulesController.text.trim(),
        'rentalItemId': widget.rentalItem.id,
        'rentalItemName': widget.rentalItem.itemName,
      };

      final message = ChatMessageModel(
        id: '',
        chatId: widget.chatId,
        senderId: currentUserId,
        message: '📄 ส่งสัญญาเช่า: ${widget.rentalItem.itemName}',
        timestamp: DateTime.now(),
        messageType: 'contract',
        contractData: contractData,
        contractStatus: 'pending', // pending, accepted, declined
      );

      await FirestoreService().sendMessage(message);

      if (mounted) {
        Navigator.pop(context); // Close the create contract screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('สร้างสัญญาเช่า'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('สิ่งของที่เช่า', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                          Text(
                            widget.rentalItem.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date Selector
              Text('ระยะเวลาเช่า', style: Theme.of(context).textTheme.titleSmall),
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
                              : 'เลือกวันเริ่ม - วันสิ้นสุด',
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
                        Text('ค่าเช่ารวม (บาท)', style: Theme.of(context).textTheme.titleSmall),
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
                            if (val == null || val.isEmpty) return 'กรุณากรอกค่าเช่า';
                            if (double.tryParse(val) == null) return 'ตัวเลขเท่านั้น';
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
                        Text('ค่ามัดจำ (บาท)', style: Theme.of(context).textTheme.titleSmall),
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
                            if (val == null || val.isEmpty) return 'กรุณากรอกค่ามัดจำ';
                            if (double.tryParse(val) == null) return 'ตัวเลขเท่านั้น';
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
              Text('ข้อตกลงและเงื่อนไขเพิ่มเติม (จุดนัดรับ/สภาพการคืน)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rulesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'เช่น นัดรับหน้า LU คืนในสภาพเดิม ห้ามเปียกน้ำ...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'กรุณาระบุข้อตกลงเบื้องต้น';
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
              onPressed: _isTranslating ? null : _sendContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isTranslating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ส่งสัญญาเช่า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
