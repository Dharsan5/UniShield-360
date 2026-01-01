import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unishield_360/providers/auth_provider.dart';
import 'package:unishield_360/providers/alert_provider.dart';
import 'package:unishield_360/screens/guardian/guardian_screen.dart';
import 'package:unishield_360/screens/brocode/locker_room_screen.dart';
import 'package:unishield_360/screens/admin/campus_eye_screen.dart';
import 'package:unishield_360/screens/profile/profile_screen.dart';
import 'package:unishield_360/widgets/sos_button.dart';
import 'package:unishield_360/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAlertProvider();
  }

  Future<void> _initializeAlertProvider() async {
    final alertProvider = context.read<AlertProvider>();
    await alertProvider.initializeLocation();

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      alertProvider.subscribeToAlerts(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Determine which tabs to show based on user role/gender
    final List<Widget> screens = [];
    final List<BottomNavigationBarItem> navItems = [];

    // Always show home
    screens.add(_buildHomeTab());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ));

    // Female users get Guardian Mode
    if (user?.isFemale == true || user?.gender == 'unknown') {
      screens.add(const GuardianScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.shield_outlined),
        activeIcon: const Icon(Icons.shield),
        label: 'Guardian',
        backgroundColor: AppTheme.guardianColor,
      ));
    }

    // Male users get Locker Room
    if (user?.isMale == true || user?.gender == 'unknown') {
      screens.add(const LockerRoomScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.forum_outlined),
        activeIcon: const Icon(Icons.forum),
        label: 'BroCode',
        backgroundColor: AppTheme.broCodeColor,
      ));
    }

    // Admin users get Campus Eye
    if (user?.isAdmin == true) {
      screens.add(const CampusEyeScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.analytics_outlined),
        activeIcon: const Icon(Icons.analytics),
        label: 'Campus Eye',
        backgroundColor: AppTheme.campusEyeColor,
      ));
    }

    // Always show profile
    screens.add(const ProfileScreen());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
      // SOS Floating Action Button - always visible
      floatingActionButton: const SOSButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHomeTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UniShield 360',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Welcome, ${user?.name ?? 'Student'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Status Card
            _buildSafetyStatusCard(),
            const SizedBox(height: 20),
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 20),
            // Feature Cards
            const Text(
              'Your Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureCards(),
            const SizedBox(height: 20),
            // Safety Tips
            _buildSafetyTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyStatusCard() {
    final alertProvider = context.watch<AlertProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alertProvider.hasActiveAlert
              ? [AppTheme.emergencyRed, AppTheme.emergencyRed.withOpacity(0.8)]
              : [AppTheme.safeGreen, AppTheme.safeGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (alertProvider.hasActiveAlert
                    ? AppTheme.emergencyRed
                    : AppTheme.safeGreen)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alertProvider.hasActiveAlert
                  ? Icons.warning_amber_rounded
                  : Icons.verified_user,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertProvider.hasActiveAlert ? 'Alert Active' : 'You\'re Safe',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alertProvider.hasActiveAlert
                      ? 'Your location is being shared'
                      : 'Campus safety status: Normal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.phone,
            label: 'Emergency',
            color: AppTheme.emergencyRed,
            onTap: () {
              // TODO: Call emergency
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.share_location,
            label: 'Share Location',
            color: AppTheme.warningYellow,
            onTap: () {
              // TODO: Share location
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.contacts,
            label: 'Contacts',
            color: AppTheme.primaryColor,
            onTap: () {
              // TODO: Show emergency contacts
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Column(
      children: [
        if (user?.isFemale == true || user?.gender == 'unknown')
          _FeatureCard(
            title: 'Guardian Mode',
            description: 'Quick safety alerts and GPS tracking',
            icon: Icons.shield,
            color: AppTheme.guardianColor,
            onTap: () {
              setState(() => _currentIndex = 1);
            },
          ),
        if (user?.isMale == true || user?.gender == 'unknown')
          _FeatureCard(
            title: 'The Locker Room',
            description: 'Anonymous peer support chat',
            icon: Icons.forum,
            color: AppTheme.broCodeColor,
            onTap: () {
              final index = user?.isFemale == true ? 2 : 1;
              setState(() => _currentIndex = index);
            },
          ),
        if (user?.isAdmin == true)
          _FeatureCard(
            title: 'Campus Eye',
            description: 'Gender analytics dashboard',
            icon: Icons.analytics,
            color: AppTheme.campusEyeColor,
            onTap: () {
              setState(() => _currentIndex = 2);
            },
          ),
      ],
    );
  }

  Widget _buildSafetyTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Safety Tip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Always share your live location with trusted contacts when traveling late at night.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }
}
