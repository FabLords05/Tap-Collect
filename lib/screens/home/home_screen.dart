import 'package:flutter/material.dart';
import 'package:grove_rewards/screens/home/customer_identity_screen.dart';
import 'package:grove_rewards/screens/home/dashboard_screen.dart';
import 'package:grove_rewards/screens/home/history_screen.dart';
import 'package:grove_rewards/screens/home/profile_screen.dart';
import 'package:grove_rewards/screens/home/rewards_screen.dart';
import 'package:grove_rewards/services/navigation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listen for external navigation requests (optional, but good practice if you kept NavigationService)
    NavigationService.currentIndex.addListener(_onNavigationRequest);
  }

  @override
  void dispose() {
    NavigationService.currentIndex.removeListener(_onNavigationRequest);
    super.dispose();
  }

  void _onNavigationRequest() {
    final idx = NavigationService.currentIndex.value;
    if (mounted && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  // This function switches the tab to 'Rewards'.
  // In our new 5-tab layout:
  // 0: Dashboard
  // 1: My ID
  // 2: Rewards  <-- We want to go here
  // 3: History
  // 4: Profile
  void _goToRewardsTab() {
    setState(() {
      _selectedIndex = 2; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 0: Dashboard
      // FIX: We pass the callback here to satisfy the required argument
      DashboardScreen(onNavigateToRewards: _goToRewardsTab),
      
      // 1: My ID (Customer Identity)
      const CustomerIdentityScreen(),

      // 2: Rewards
      const RewardsScreen(),

      // 3: History
      const HistoryScreen(),

      // 4: Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code),
            selectedIcon: Icon(Icons.qr_code_2), // Optional distinct icon
            label: 'My ID',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}