import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/prediction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/single_predict_screen.dart';
import 'screens/batch_predict_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'utils/constants.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChurnIntelligenceApp());
}

/// ── Root Application ───────────────────────────────────────────────────────
class ChurnIntelligenceApp extends StatelessWidget {
  const ChurnIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Churn Intelligence System',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

/// ── App Shell with Navigation ──────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  bool _showAuthScreen = false;
  bool _isRegistering = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Check API health on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PredictionProvider>(context, listen: false);
      provider.checkApiHealth();
      provider.loadHistory();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Conditionally render Landing Page or Auth Split-Screen if not logged in
    if (!_isLoggedIn) {
      if (_showAuthScreen) {
        return Scaffold(
          body: _buildAuthScreen(isDesktop),
        );
      }
      return Scaffold(
        body: HomeScreen(
          isLoggedIn: false,
          onSignIn: () {
            setState(() {
              _showAuthScreen = true;
              _isRegistering = false;
            });
          },
          onSignUp: () {
            setState(() {
              _showAuthScreen = true;
              _isRegistering = true;
            });
          },
        ),
      );
    }

    final screens = [
      HomeScreen(
        onNavigate: _navigateTo,
        isLoggedIn: true,
      ),
      const SinglePredictScreen(),
      const BatchPredictScreen(),
      const DashboardScreen(),
      const AboutScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopNav(),
            VerticalDivider(width: 1, thickness: 1, color: context.border),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Divider(height: 1, thickness: 1, color: context.border),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet
    return Scaffold(
      appBar: _buildMobileAppBar(),
      drawer: isTablet ? null : _buildDrawer(),
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// ── Desktop Side Navigation ──────────────────────────────────────────────
  /// ── Desktop Side Navigation ──────────────────────────────────────────────
  Widget _buildDesktopNav() {
    return Container(
      width: 280,
      color: context.isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
      child: Column(
        children: [
          // Header Logo & Branding
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Churn Intelligence',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Professional retention insights',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Navigation Menu Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _navItem(1, Icons.person_search_outlined,
                      Icons.person_search, 'Single Predict'),
                  _navItem(2, Icons.group_work_outlined, Icons.group_work,
                      'Batch Predict'),
                  _navItem(3, Icons.dashboard_outlined,
                      Icons.dashboard_customize, 'Dashboard'),
                  _navItem(4, Icons.info_outline, Icons.info, 'About'),
                  
                  const Spacer(),
                  
                  // CRM & Integration Status (Inspired by Gainsight & ChurnZero)
                  _buildIntegrationsWidget(),
                  const SizedBox(height: 12),
                  
                  // API Status Connection
                  Consumer<PredictionProvider>(
                    builder: (context, provider, _) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: provider.isApiConnected
                              ? context.successSurface
                              : context.errorSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: provider.isApiConnected
                                ? context.success.withOpacity(0.2)
                                : context.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: provider.isApiConnected
                                    ? context.success
                                    : context.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.isApiConnected
                                    ? 'System Engine Connected'
                                    : 'System Engine Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: provider.isApiConnected
                                      ? context.success
                                      : context.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Profile Section (Gainsight SaaS CSM visual style)
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? context.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 14, color: context.primary),
              const SizedBox(width: 6),
              Text(
                'CRM INTEGRATIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _integrationRow('Salesforce CRM', true),
          const SizedBox(height: 6),
          _integrationRow('Zendesk Support', true),
          const SizedBox(height: 6),
          _integrationRow('HubSpot Suite', false),
        ],
      ),
    );
  }

  Widget _integrationRow(String name, bool connected) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: connected ? context.success : context.textSecondary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          connected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            fontSize: 9,
            color: connected ? context.success : context.textSecondary.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.primary.withOpacity(0.2),
            child: Icon(Icons.person, size: 16, color: context.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Arief CS Manager',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  'Customer Success Team',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined, size: 16, color: context.textSecondary),
            onPressed: () {
              setState(() {
                _isLoggedIn = false;
                _showAuthScreen = false;
                _selectedIndex = 0;
              });
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _navigateTo(index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected
                      ? context.primary
                      : context.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? context.primary
                        : context.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final titles = [
      'Home',
      'Single Prediction',
      'Batch Prediction',
      'Dashboard',
      'About',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          bottom: BorderSide(color: context.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Churn Intelligence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.primary,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Text(
            titles[_selectedIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const Spacer(),

          Consumer<PredictionProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  if (provider.history.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${provider.history.length} predictions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.primary,
                        ),
                      ),
                    ),
                  if (provider.history.isNotEmpty) const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: provider.isApiConnected
                          ? context.successSurface
                          : context.errorSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: provider.isApiConnected
                                ? context.success
                                : context.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isApiConnected ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: provider.isApiConnected
                                ? context.success
                                : context.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// ── Mobile App Bar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Churn Intelligence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      backgroundColor: context.surface,
      elevation: 0,
      actions: [

        Consumer<PredictionProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: provider.isApiConnected
                        ? context.success
                        : context.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// ── Drawer ───────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: context.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Churn Intelligence',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'AI-Powered Prediction System',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(0, Icons.home, 'Home'),
          _drawerItem(1, Icons.person_search, 'Single Prediction'),
          _drawerItem(2, Icons.group_work, 'Batch Prediction'),
          _drawerItem(3, Icons.dashboard_customize, 'Dashboard'),
          _drawerItem(4, Icons.info_outline, 'About'),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: context.error),
            title: Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isLoggedIn = false;
                _showAuthScreen = false;
                _selectedIndex = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? context.primary : context.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? context.primary : context.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: context.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        _navigateTo(index);
        Navigator.pop(context);
      },
    );
  }

  /// ── Bottom Navigation ────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _navigateTo,
        backgroundColor: context.surface,
        elevation: 0,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 22),
            selectedIcon: Icon(Icons.home, size: 22),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined, size: 22),
            selectedIcon: Icon(Icons.person_search, size: 22),
            label: 'Predict',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_work_outlined, size: 22),
            selectedIcon: Icon(Icons.group_work, size: 22),
            label: 'Batch',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 22),
            selectedIcon: Icon(Icons.dashboard_customize, size: 22),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline, size: 22),
            selectedIcon: Icon(Icons.info, size: 22),
            label: 'About',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthScreen(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          // Left side - SaaS branding & Quote
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.primary, context.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Churn Intelligence',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'The workspace for customer retention analytics.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join thousands of Customer Success teams diagnosing risk and managing client playbooks with ML-driven insights.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '“Integrating this platform reduced our customer churn by 42% in the first quarter.”',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sarah Jenkins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'VP of Customer Success, Zendesk',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
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
          
          // Right side - Form
          Expanded(
            flex: 6,
            child: Container(
              color: context.background,
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildAuthForm(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile / Tablet view
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.primary.withOpacity(0.08),
            context.background,
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildAuthForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _showAuthScreen = false;
              });
            },
            icon: Icon(Icons.arrow_back, color: context.textSecondary),
            tooltip: 'Back to Homepage',
          ),
          const SizedBox(height: 16),
          Text(
            _isRegistering ? 'Create your CS Workspace' : 'Sign in to Churn Intelligence',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRegistering
                ? 'Get 14 days free trial. No credit card required.'
                : 'Enter your work email and password below.',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = true;
                      _showAuthScreen = false;
                    });
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 20),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimary,
                    side: BorderSide(color: context.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = true;
                      _showAuthScreen = false;
                    });
                  },
                  icon: const Icon(Icons.vpn_key_outlined, size: 14),
                  label: const Text('SSO Key'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimary,
                    side: BorderSide(color: context.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: context.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR CONTINUE WITH EMAIL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textTertiary),
                ),
              ),
              Expanded(child: Divider(color: context.border)),
            ],
          ),
          const SizedBox(height: 20),

          if (_isRegistering) ...[
            Text(
              'Full Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('auth_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Sarah Jenkins',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your name';
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Work Email',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('auth_email_field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'sarah.jenkins@company.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter your email';
              if (!val.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              if (!_isRegistering)
                TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const ValueKey('auth_password_field'),
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) {
              if (val == null || val.length < 5) return 'Password must be at least 5 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() == true) {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final apiService = ApiService();
                          if (_isRegistering) {
                            await apiService.signup(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              _nameController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Workspace created successfully! Please sign in.'),
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() {
                              _isRegistering = false;
                              _isLoading = false;
                              _passwordController.clear();
                            });
                          } else {
                            final result = await apiService.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Welcome back, ${result['name'] ?? 'CS Manager'}!'),
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() {
                              _isLoggedIn = true;
                              _showAuthScreen = false;
                              _isLoading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Authentication Failed: ${e.toString().replaceAll('ApiException:', '')}'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: context.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isRegistering ? 'Create Workspace' : 'Sign In',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isRegistering = !_isRegistering;
                });
              },
              child: Text(
                _isRegistering ? 'Already have an account? Log in' : 'Don\'t have an account? Sign up',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
