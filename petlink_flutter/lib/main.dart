import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state/app_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/config_screen.dart';
import 'widgets/ai_chatbot_sheet.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const PetLinkApp(),
    ),
  );
}

class PetLinkApp extends StatelessWidget {
  const PetLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    // Define Theme colors
    const primaryColor = Color(0xFFF39C12);
    const bgLight = Color(0xFFF8FAFC);
    const bgDark = Color(0xFF0F172A);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(primary: primaryColor, secondary: primaryColor),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(primary: primaryColor, secondary: primaryColor),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'PetLink',
      theme: state.isDarkMode ? darkTheme : lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CameraScreen(),
    const ScheduleScreen(),
    const AlertsScreen(),
    const ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final pendingAlerts = state.pendingAlertsCount;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(LucideIcons.pawPrint, color: theme.primaryColor, size: 28),
            const SizedBox(width: 8),
            const Text('PetLink', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: state.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.isConnected ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://api.dicebear.com/7.x/notionists/png?seed=Max&backgroundColor=F39C12'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AIChatbotSheet(),
          );
        },
        backgroundColor: theme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.messageSquare, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: [
          const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Inicio'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.video), label: 'Cámara'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Horarios'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.bell),
                if (pendingAlerts > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        pendingAlerts.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alertas',
          ),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Config'),
        ],
      ),
    );
  }
}
