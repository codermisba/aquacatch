// Create this as lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aquacatch/main.dart';

import 'components.dart';
import 'home_screen.dart';
import 'assesment_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  DateTime? lastBackPressTime;

  // List of pages corresponding to bottom navigation items
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(), // Home
      const TutorialsPage(), // Search
      const AssessmentPage(), // Assessment
      const ReportsPage(), // Reports
      ProfilePage(
        // Profile
        setLocale: (locale) {
          MyApp.setLocale(context, locale);
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get appropriate app bar title based on selected index
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "AquaCatch";
      case 1:
        return "Tutorials";
      case 2:
        return "Assessment";
      case 3:
        return "Reports";
      case 4:
        return "Profile";
      default:
        return "AquaCatch";
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back press - exit only from home screen
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Go to home screen
          });
          return false;
        }

        DateTime now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Press back again to exit")),
          );
          return false;
        }
        // Exit the app
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(1, 86, 112, 1),
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // Control leading manually
          leading: _selectedIndex != 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Navigate back to dashboard (Home)
                    });
                  },
                )
              : null,
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
        // Bottom Navigation Bar from HomeScreen
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tutorials'),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Assessment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Reports',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// Search Page
class TutorialsPage extends StatefulWidget {
  const TutorialsPage({super.key});

  @override
  State<TutorialsPage> createState() => _TutorialsPageState();
}

class _TutorialsPageState extends State<TutorialsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Sample tutorials list
  final List<Map<String, String>> tutorials = [
    {
      "title": "Getting Started",
      "description": "Learn how to set up the app and use its features.",
    },
    {
      "title": "Rainwater Harvesting",
      "description": "Step-by-step guide on collecting and storing rainwater.",
    },
    {
      "title": "Artificial Recharge",
      "description": "Learn how to recharge groundwater easily.",
    },
    {
      "title": "Water Filtration",
      "description": "Simple methods to filter water at home.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Optional: Search Bar for tutorials
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tutorials...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 20),

          // Tutorials list
          Expanded(
            child: ListView.builder(
              itemCount: tutorials.length,
              itemBuilder: (context, index) {
                final tutorial = tutorials[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.blue,
                      size: 40,
                    ),
                    title: Text(
                      tutorial['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tutorial['description']!),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Placeholder for navigation to tutorial detail
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Clicked on ${tutorial['title']}"),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Reports Page
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports Header
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.description, size: 40, color: primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Assessment Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View and download your water conservation reports',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Placeholder content
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Reports Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete an assessment to\ngenerate your first report!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
