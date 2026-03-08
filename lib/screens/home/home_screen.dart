import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_tab.dart';
import '../rentals/my_rentals_screen.dart';
import '../rentals/post_rental_screen.dart';
import '../rentals/post_request_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../config/theme.dart';
import '../../config/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const MyRentalsScreen(),
    const PostTab(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: StreamBuilder<int>(
        stream: currentUserId != null
            ? FirestoreService().getTotalUnreadCount(currentUserId)
            : const Stream.empty(),
        builder: (context, unreadSnapshot) {
          final totalUnread = unreadSnapshot.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: l.tr('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag_outlined),
                activeIcon: const Icon(Icons.shopping_bag),
                label: l.tr('nav_rent'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_circle_outline),
                activeIcon: const Icon(Icons.add_circle),
                label: l.tr('nav_post'),
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: totalUnread > 0,
                  label: Text(
                    totalUnread > 99 ? '99+' : '$totalUnread',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: AppTheme.error,
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  isLabelVisible: totalUnread > 0,
                  label: Text(
                    totalUnread > 99 ? '99+' : '$totalUnread',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: AppTheme.error,
                  child: const Icon(Icons.chat_bubble),
                ),
                label: l.tr('nav_chat'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: l.tr('nav_profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Post Tab - shows options to post rental or request
class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tr('post_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.tr('post_what_to_do'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Post Item Card
            _PostOptionCard(
              icon: Icons.add_circle_outline,
              title: l.tr('post_item_title'),
              subtitle: l.tr('post_item_sub'),
              color: AppTheme.primaryTeal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PostRentalScreen()),
              ),
            ),
            const SizedBox(height: 16),
            // Request Item Card
            _PostOptionCard(
              icon: Icons.search,
              title: l.tr('post_request_title'),
              subtitle: l.tr('post_request_sub'),
              color: AppTheme.accentMint,
              textColor: AppTheme.primaryTeal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PostRequestScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _PostOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: effectiveTextColor, size: 40),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: effectiveTextColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: effectiveTextColor.withAlpha(220),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_forward, color: effectiveTextColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
