import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'rental_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();

    if (authService.currentUser != null) {
      final userData = await firestoreService.getUserData(
        authService.currentUser!.uid,
      );
      if (mounted) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      }
    }
  }

  /// ดึงชื่อจริงจาก KU email format: chaimongkhon.na@ku.th → Chaimongkhon
  String _getFirstNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final localPart = email.split('@').first; // chaimongkhon.na
    final firstName = localPart.split('.').first; // chaimongkhon
    if (firstName.isEmpty) return 'User';
    return firstName[0].toUpperCase() + firstName.substring(1);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Menu Items
            _buildMenuSection(),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar — show Google photo if available, otherwise initial letter
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primaryTeal,
                child: _user?.photoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _user!.photoUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Text(
                            _getFirstNameFromEmail(_user?.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Text(
                            _getFirstNameFromEmail(_user?.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _getFirstNameFromEmail(_user?.email)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (_user?.isVerified == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: AppTheme.secondaryGreen,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // First name from email
          Text(
            _getFirstNameFromEmail(_user?.email),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),

          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 20),
              const SizedBox(width: 4),
              Text(
                (_user?.rating ?? 0.0).toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                ' (${_user?.totalReviews ?? 0} reviews)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Verify Button (if not verified)
          if (_user?.isVerified != true)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to verification screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID verification coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.verified_user, size: 20),
              label: const Text('Get Verified'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Rentals',
            '${_user?.totalRentals ?? 0}',
            Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: firestoreService
                .getUserRentalItems(authService.currentUser!.uid)
                .first,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildStatCard(
                'Items Listed',
                '$count',
                Icons.inventory_2_outlined,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
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
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Rental History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RentalHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () => _showEditProfileDialog(),
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ระบบแจ้งเตือนจะเปิดใช้ได้ในเร็วๆ นี้'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Help & Support'),
                  content: const Text('ติดต่อผู้ดูแลระบบ:\nkasetrentshare@ku.th\n\nเวลาทำการ: จันทร์-ศุกร์ 9:00-17:00 น.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ตกลง'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Kaset RentShare',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Kasetsart University',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _user?.name ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขโปรไฟล์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              try {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                await authService.updateUserData(
                  authService.currentUser!.uid,
                  {'name': newName},
                );
                // Reload profile
                await _loadUserData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('อัปเดตโปรไฟล์สำเร็จ'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
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
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
