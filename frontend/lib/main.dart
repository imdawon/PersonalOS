import 'package:flutter/material.dart';
import 'package:PersonalOS/providers/activity_provider.dart';
import 'package:PersonalOS/screens/dashboard_screen.dart';
import 'package:PersonalOS/screens/unclassified_screen.dart';
import 'package:provider/provider.dart';

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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(_selectedIndex == 0 ? 'Today\'s Dashboard' : 'Unclassified Activities'),
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
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.help_outline),
          label: 'Classify',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    ),
  );
}
}