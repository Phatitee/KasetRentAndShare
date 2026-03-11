import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage;
  bool _isSaving = false;
  late String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = widget.user.photoUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedImage == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new photo to Cloudinary
      final cloudinary = CloudinaryService();
      final newPhotoUrl = await cloudinary.uploadImage(_selectedImage!, 'profile_photos');

      // Update Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserData(
        authService.currentUser!.uid,
        {'photoUrl': newPhotoUrl},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตรูปโปรไฟล์สำเร็จ!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true); // true = data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// ดึงชื่อจริงจาก KU email
  String _getFirstNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final localPart = email.split('@').first;
    final firstName = localPart.split('.').first;
    if (firstName.isEmpty) return 'User';
    return firstName[0].toUpperCase() + firstName.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.name.isNotEmpty
        ? widget.user.name
        : _getFirstNameFromEmail(widget.user.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'บันทึก',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Photo
          Center(
            child: Stack(
              children: [
                _selectedImage != null
                    ? CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryTeal,
                        child: ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : UserAvatar(
                        photoUrl: _currentPhotoUrl,
                        name: displayName,
                        radius: 60,
                        fontSize: 48,
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickImage,
              child: Text(
                'เปลี่ยนรูปโปรไฟล์',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Name (read-only)
          _buildReadOnlyField(
            label: 'ชื่อ',
            value: displayName,
            icon: Icons.person_outline,
            lockMessage: 'ไม่สามารถเปลี่ยนชื่อได้',
          ),
          const SizedBox(height: 20),

          // Email (read-only)
          _buildReadOnlyField(
            label: 'อีเมล',
            value: widget.user.email,
            icon: Icons.email_outlined,
            lockMessage: 'อีเมลไม่สามารถเปลี่ยนได้',
          ),
          const SizedBox(height: 20),

          // Verified status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.user.isVerified
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.user.isVerified
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.user.isVerified ? Icons.verified : Icons.info_outline,
                  color: widget.user.isVerified
                      ? AppTheme.success
                      : AppTheme.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.user.isVerified
                        ? 'บัญชีของคุณได้รับการยืนยันแล้ว ✓'
                        : 'บัญชียังไม่ได้รับการยืนยัน',
                    style: TextStyle(
                      color: widget.user.isVerified
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Text(
      name.substring(0, 1).toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String lockMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textHint, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.lock_outline, color: AppTheme.textHint, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text(
              lockMessage,
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
