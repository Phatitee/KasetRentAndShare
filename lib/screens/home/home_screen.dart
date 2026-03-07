import 'package:flutter/material.dart';
import 'home_tab.dart';
import '../rentals/my_rentals_screen.dart';
import '../rentals/post_rental_screen.dart';
import '../rentals/post_request_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../config/theme.dart';

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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Rent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Post Tab - shows options to post rental or request
class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What would you like to do?',
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
              title: 'Post an Item',
              subtitle: 'List your gear for others to rent and start earning',
              color: AppTheme.primaryTeal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PostRentalScreen()),
              ),
            ),
            const SizedBox(height: 16),
            // Request Item Card
            _PostOptionCard(
              icon: Icons.search,
              title: 'Request an Item',
              subtitle: 'Looking to rent something? Post a request and let owners come to you',
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
