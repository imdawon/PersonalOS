import 'package:flutter/material.dart';
import 'package:PersonalOS/providers/activity_provider.dart';
import 'package:PersonalOS/screens/dashboard_screen.dart';
import 'package:PersonalOS/screens/unclassified_screen.dart';
import 'package:provider/provider.dart';
import 'screens/logbook_screen.dart';
import 'package:PersonalOS/screens/skills_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ActivityProvider(),
      child: MaterialApp(
        title: 'Personal OS',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    UnclassifiedScreen(),
    LogbookScreen(),
    SkillsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Automatically fetch data when switching to the classify tab (index 1)
    if (index == 1) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      // Fetch unclassified data specifically for the classify tab
      provider.fetchUnclassifiedData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Today\'s Dashboard' :
               _selectedIndex == 1 ? 'Unclassified Activities' :
               _selectedIndex == 2 ? 'Logbook' : 'Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ActivityProvider>(context, listen: false).fetchAllData();
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'Classify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Logbook',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Skills',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}