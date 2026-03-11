import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/rental_contract_model.dart';
import '../../utils/pdf_generator.dart';
import '../reviews/write_review_screen.dart';

class ContractDetailsScreen extends StatefulWidget {
  final RentalContractModel contract;
  const ContractDetailsScreen({super.key, required this.contract});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  late RentalContractModel _contract;
  bool _isLoading = false;
  bool _hasReviewed = true; // Default to true until checked

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
    _checkReviewStatus();
  }

  Future<void> _checkReviewStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser!.uid;
    final hasReviewed = await FirestoreService().hasUserReviewedContract(_contract.id, userId);
    if (mounted) {
      setState(() => _hasReviewed = hasReviewed);
    }
  }

  // --- Helper Methods ---

  Future<Position?> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(GeoPoint p1, GeoPoint p2) {
    return Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  }

  Future<String?> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile == null) return null;

    setState(() => _isLoading = true);
    final cloudinary = CloudinaryService();
    final url = await cloudinary.uploadImage(File(pickedFile.path), 'contract_evidence');
    setState(() => _isLoading = false);
    return url;
  }

  Future<void> _uploadPaymentSlip() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final cloudinary = CloudinaryService();
      final url = await cloudinary.uploadImage(File(pickedFile.path), 'payment_slips');
      
      if (url != null) {
        await FirestoreService().updateContract(_contract.id, {
          'paymentSlipUrl': url,
        });

        // Send status message to chat
        if (_contract.chatId.isNotEmpty) {
          await FirestoreService().sendSystemMessage(_contract.chatId, 'ผู้เช่าอัปโหลดสลิปการโอนเงินแล้ว');
        }

        _refreshContract();
        _showSuccess('อัปโหลดสลิปสำเร็จ รอยืนยันจากผู้ให้เช่า');
      }
    } catch (e) {
      _showError('อัปโหลดล้มเหลว: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    try {
      await FirestoreService().updateContract(_contract.id, {
        'paymentStatus': 'paid',
        'paymentConfirmedAt': Timestamp.now(),
      });

      // Send status message to chat
      if (_contract.chatId.isNotEmpty) {
        await FirestoreService().sendSystemMessage(_contract.chatId, 'ผู้ให้เช่ายืนยันการรับเงินเรียบร้อยแล้ว');
      }

      _refreshContract();
      _showSuccess('ยืนยันการชำระเงินสำเร็จ');
    } catch (e) {
      _showError('ยืนยันล้มเหลว: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Core Handover Logic ---

  Future<void> _handlePickup(bool isOwner) async {
    final pos = await _getCurrentLocation();
    if (pos == null) return;
    final myLoc = GeoPoint(pos.latitude, pos.longitude);

    // 1. Proximity Check (if I'm the second one)
    final otherLoc = isOwner ? _contract.renterPickupLocation : _contract.ownerPickupLocation;
    if (otherLoc != null) {
      final dist = _calculateDistance(myLoc, otherLoc);
      if (dist > 100) { // 100 meters
        _showError('คุณต้องอยู่ใกล้กับคู่สัญญาเพื่อยืนยันการรับส่งของ (ระยะห่างปัจจุบัน: ${dist.toInt()}ม.)');
        return;
      }
    }

    // 2. Proof of Pickup (Photo)
    final photoUrl = await _takePhoto();
    if (photoUrl == null) return;

    setState(() => _isLoading = true);
    try {
      final updateData = <String, dynamic>{
        isOwner ? 'ownerPickupConfirmed' : 'renterPickupConfirmed': true,
        isOwner ? 'ownerPickupLocation' : 'renterPickupLocation': myLoc,
        'pickupPhotoUrl': photoUrl, // Update photo
      };

      // Both confirmed?
      bool bothConfirmed = false;
      if ((isOwner && _contract.renterPickupConfirmed) || (!isOwner && _contract.ownerPickupConfirmed)) {
        updateData['pickupConfirmedAt'] = Timestamp.now();
        bothConfirmed = true;
      }

      await FirestoreService().updateContract(_contract.id, updateData);

      // Send status message to chat
      if (_contract.chatId.isNotEmpty) {
        final role = isOwner ? 'ผู้ให้เช่า' : 'ผู้เช่า';
        await FirestoreService().sendSystemMessage(_contract.chatId, 'ยืนยันการรับของแล้ว ($role)');
        if (bothConfirmed) {
          await FirestoreService().sendSystemMessage(_contract.chatId, 'การรับของเสร็จสมบูรณ์');
        }
      }

      _refreshContract();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReturn(bool isOwner) async {
    final pos = await _getCurrentLocation();
    if (pos == null) return;
    final myLoc = GeoPoint(pos.latitude, pos.longitude);

    // 1. Proximity Check
    final otherLoc = isOwner ? _contract.renterReturnLocation : _contract.ownerReturnLocation;
    if (otherLoc != null) {
      final dist = _calculateDistance(myLoc, otherLoc);
      if (dist > 100) {
        _showError('คุณต้องอยู่ใกล้กับคู่สัญญาเพื่อยืนยันการคืนของ');
        return;
      }
    }

    // 2. Photo Evidence
    final photoUrl = await _takePhoto();
    if (photoUrl == null) return;

    setState(() => _isLoading = true);
    try {
      final updateData = <String, dynamic>{
        isOwner ? 'ownerReturnConfirmed' : 'renterReturnConfirmed': true,
        isOwner ? 'ownerReturnLocation' : 'renterReturnLocation': myLoc,
        'returnPhotoUrl': photoUrl,
      };

      bool bothConfirmed = false;
      if ((isOwner && _contract.renterReturnConfirmed) || (!isOwner && _contract.ownerReturnConfirmed)) {
        updateData['returnConfirmedAt'] = Timestamp.now();
        bothConfirmed = true;
        // Show automatic review prompt after state update
        _showReviewPrompt();
      }

      await FirestoreService().updateContract(_contract.id, updateData);

      // Send status message to chat
      if (_contract.chatId.isNotEmpty) {
        final role = isOwner ? 'ผู้ให้เช่า' : 'ผู้เช่า';
        await FirestoreService().sendSystemMessage(_contract.chatId, 'ยืนยันการคืนของแล้ว ($role)');
        if (bothConfirmed) {
          await FirestoreService().sendSystemMessage(_contract.chatId, 'การคืนของเสร็จสมบูรณ์');
        }
      }

      _refreshContract();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReviewPrompt() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('🎉 คืนของสำเร็จ!'),
          content: const Text('การเช่าเสร็จสมบูรณ์แล้ว คุณต้องการเขียนรีวิวให้คู่สัญญาตอนนี้เลยไหม?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ไว้ทีหลัง'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToReview();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              child: const Text('เขียนรีวิวเลย'),
            ),
          ],
        ),
      );
    });
  }

  void _navigateToReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(contract: _contract),
      ),
    );

    if (result == true) {
      _checkReviewStatus();
    }
  }

  Future<void> _refreshContract() async {
    final updated = await FirestoreService().getContract(_contract.id);
    if (updated != null) {
      setState(() => _contract = updated);
      _checkReviewStatus();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
  }

  // --- UI Parts ---

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
    final isOwner = currentUserId == _contract.ownerId;
    final isPaid = _contract.paymentStatus == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfGenerator.generateContractPdf(_contract),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_contract.isReturnComplete && !_hasReviewed)
                _buildReviewBanner(),
              _buildPaymentSection(isOwner),
              const SizedBox(height: 16),
              _buildFlowStep('1. รับของ (Pickup)', _contract.ownerPickupConfirmed, _contract.renterPickupConfirmed, _contract.pickupPhotoUrl, () => _handlePickup(isOwner), isOwner, enabled: isPaid),
              const SizedBox(height: 16),
              _buildFlowStep('2. คืนของ (Return)', _contract.ownerReturnConfirmed, _contract.renterReturnConfirmed, _contract.returnPhotoUrl, () => _handleReturn(isOwner), isOwner, enabled: _contract.isPickupComplete),
              const SizedBox(height: 24),
              _buildInfoSection(),
              if (_contract.isReturnComplete) ...[
                const SizedBox(height: 24),
                _buildReviewSection(currentUserId),
              ],
            ],
          ),
    );
  }

  Widget _buildPaymentSection(bool isOwner) {
    final isPaid = _contract.paymentStatus == 'paid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('การชำระเงิน (Payment)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isPaid)
                  const Icon(Icons.check_circle, color: AppTheme.success),
              ],
            ),
            const SizedBox(height: 12),
            if (_contract.paymentSlipUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_contract.paymentSlipUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            if (isPaid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.success.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: const Text('ชำระเงินเรียบร้อยแล้ว', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
              )
            else if (!isOwner) ...[
              // Renter view
              if (_contract.paymentSlipUrl == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploadPaymentSlip,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('อัปโหลดสลิปโอนเงิน'),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: const Text('รอยืนยันจากผู้ให้เช่า', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
            ] else ...[
              // Owner view
              if (_contract.paymentSlipUrl == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: const Text('รอผู้เช่าอัปโหลดสลิป', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmPayment,
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันการรับเงิน'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'การเช่าสำเร็จแล้ว! อย่าลืมให้คะแนนคู่สัญญาของคุณเพื่อช่วยให้ชุมชนน่าเชื่อถือขึ้น',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('เขียนรีวิวทันที'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String title, bool ownerOk, bool renterOk, String? photo, VoidCallback onConfirm, bool isOwner, {bool enabled = true}) {
    final myOk = isOwner ? ownerOk : renterOk;
    final otherOk = isOwner ? renterOk : ownerOk;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIcon('เจ้าของ', ownerOk),
                _buildStatusIcon('ผู้เช่า', renterOk),
              ],
            ),
            const SizedBox(height: 16),
            if (photo != null) 
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(photo, height: 100, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (enabled && !myOk) ? onConfirm : null,
                icon: const Icon(Icons.camera_alt),
                label: Text(myOk ? 'รอยืนยันอีกฝ่าย...' : 'ถ่ายรูปและยืนยัน'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String label, bool ok) {
    return Column(
      children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: ok ? AppTheme.success : Colors.grey),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ข้อมูลสัญญา', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('สินค้า: ${_contract.itemName}'),
            Text('ราคา: ฿${_contract.totalAmount}'),
            Text('มัดจำ: ฿${_contract.deposit}'),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(String userId) {
    if (_hasReviewed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            SizedBox(width: 8),
            Text(
              'คุณได้ให้รีวิวแล้ว ขอบคุณครับ!',
              style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _navigateToReview,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
      child: const Text('เขียนรีวิว'),
    );
  }
}
