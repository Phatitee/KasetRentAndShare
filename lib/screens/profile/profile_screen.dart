import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../reviews/user_reviews_screen.dart';
import '../contracts/contracts_list_screen.dart';
import '../../widgets/user_avatar.dart';
import 'rental_history_screen.dart';
import 'edit_profile_screen.dart';

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
      final uid = authService.currentUser!.uid;
      
      // Sync verification status based on history before/while loading
      await firestoreService.syncUserVerificationStatus(uid);
      
      final userData = await firestoreService.getUserData(uid);
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
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.tr('logout')),
        content: Text(l.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(l.tr('logout')),
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
    final l = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('profile_title')),
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
              label: Text(
                l.tr('logout'),
                style: const TextStyle(color: AppTheme.error),
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
          // Avatar
          Stack(
            children: [
              UserAvatar(
                photoUrl: _user?.photoUrl,
                name: _user?.name ?? 'User',
                radius: 48,
                fontSize: 36,
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
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = FirestoreService();
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l.tr('total_rentals_label'),
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
                l.tr('items_listed_label'),
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
    final l = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context);

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
            title: l.tr('rental_history'),
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
            icon: Icons.star_outline,
            title: l.tr('my_reviews'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserReviewsScreen(
                    userId: authService.currentUser!.uid,
                    userName: _user?.name ?? 'User',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: l.tr('my_contracts'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ContractsListScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.edit,
            title: l.tr('edit_profile'),
            onTap: () async {
              if (_user != null) {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _user!),
                  ),
                );
                if (result == true) {
                  _loadUserData(); // refresh profile
                }
              }
            },
          ),
          const Divider(height: 1),
          
          // Language Toggle (Block style [ไทย | Eng])
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.primaryTeal),
            title: Text(l.tr('language')),
            trailing: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thai Block
                  GestureDetector(
                    onTap: () {
                      if (!localeProvider.isThai) localeProvider.setLocale('th');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: localeProvider.isThai
                            ? AppTheme.primaryTeal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ไทย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: localeProvider.isThai
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // English Block
                  GestureDetector(
                    onTap: () {
                      if (!localeProvider.isEnglish) localeProvider.setLocale('en');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: localeProvider.isEnglish
                            ? AppTheme.primaryTeal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Eng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: localeProvider.isEnglish
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          _buildMenuItem(
            icon: Icons.help_outline,
            title: l.tr('help_support'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.tr('help_title')),
                  content: Text('${l.tr('help_contact')}\nkasetrentshare@ku.th\n\n${l.tr('help_hours')}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.tr('ok')),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          
          // Version info (Moved from Settings)
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryTeal),
            title: Text(l.tr('version')),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
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

}
