import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int reportCount = 0;
  double waterSaved = 0.0;
  final user = FirebaseAuth.instance.currentUser;

  final List<String> imageUrls = [
    "https://cdn1.byjus.com/wp-content/uploads/2023/05/Rainwater-harvesting-1.png",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/RWH-image.jpg/800px-RWH-image.jpg",
  ];

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the async function like this:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCounts(); // ensures the widget is fully built before fetching
    });
  }

  Future<void> _fetchCounts() async {
    if (user == null) return;

    try {
      // Fetch reports
      final reportSnapshot = await FirebaseFirestore.instance
          .collection("results")
          .where('userId', isEqualTo: user!.uid)
          .get();

      // Fetch assessments
      // final assessmentSnapshot = await FirebaseFirestore.instance
      //     .collection("assessments")
      //     .where('userId', isEqualTo: user!.uid)
      //     .get();

      double latestWaterSaved = 0;
      if (reportSnapshot.docs.isNotEmpty) {
        final latestReport = reportSnapshot.docs.last.data();
        latestWaterSaved = (latestReport['potentialLiters'] ?? 0).toInt();
      }

      setState(() {
        reportCount = reportSnapshot.docs.length;
        waterSaved =
            latestWaterSaved; // show water saved instead of past assessments
      });

      print("Reports: $reportCount, Water Saved: $latestWaterSaved");
    } catch (e) {
      print("Error fetching counts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed all Scaffold, AppBar, BottomNavigationBar, WillPopScope
    // Now only contains the content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTopSection(context),
          const SizedBox(height: 25),

          const SizedBox(height: 40),

          // Know More Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Learn More About Rainwater Harvesting",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),

          // Learning Cards Section
          _buildLearningCards(context),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Important links",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start, // align at top
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => _launchURL('https://cgwb.gov.in/'),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // ✅ added here
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 120, // ✅ set same height for both cards
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 40,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Central Ground Water Board",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () =>
                        _launchURL('https://www.jalshakti-dowr.gov.in/'),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // ✅ already present
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 120, // ✅ same height here
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 40,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Ministry of JalShakti.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Top Section ----------------
  Widget _buildTopSection(BuildContext context) {
    return Column(
      children: [
        // Quic Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox("Past Assessments", "12", Icons.history, Colors.blue),
            _buildStatBox("Reports", "5", Icons.description, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Learning Cards Section ----------------
  Widget _buildLearningCards(BuildContext context) {
    final List<Map<String, dynamic>> learningTopics = [
      {
        'title': 'What is Rainwater Harvesting',
        'description':
            'Learn the basics of collecting and storing rainwater for various uses',
        'image': 'assets/images/small.png',
        'icon': Icons.water_drop,
        'color': const Color.fromARGB(255, 0, 176, 207),
        'route': '/rainwater_harvesting',
      },
      {
        'title': 'Artificial Recharge',
        'description':
            'Discover methods to artificially recharge groundwater aquifers',
        'image': 'assets/images/artificial_recharge.png',
        'icon': Icons.layers,
        'color': const Color.fromARGB(255, 62, 160, 66),
        'route': '/artificial_recharge',
      },
      {
        'title': 'Rooftop Rain Water Harvesting',
        'description':
            'Explore techniques for collecting rainwater from building rooftops',
        'image': 'assets/images/rtrwh.png',
        'icon': Icons.home,
        'color': const Color.fromARGB(255, 204, 139, 40),
        'route': '/rooftop_rainwaterharvesting',
      },
      {
        'title': 'Why Fresh Water Matters',
        'description':
            'Fresh water plays a vital role in replenishing underground aquifers. It helps maintain soil permeability and ensures that groundwater remains a sustainable resource for communities and ecosystems.',
        'image': 'assets/images/fresh_water.png',
        'icon': Icons.terrain,
        'color': const Color.fromARGB(255, 189, 126, 103),
        'route': '/fresh_water',
      },
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600; // 👈 breakpoint

    if (isMobile) {
      // 📱 Mobile → full width + small padding
      return Column(
        children: learningTopics.map((topic) {
          return Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ), // ✅ extra padding
            width: double.infinity,
            child: _buildLearningCard(context, topic),
          );
        }).toList(),
      );
    } else {
      // 💻 Web/Tablet → side-by-side row
      return Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: learningTopics.map((topic) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, minWidth: 250),
              child: _buildLearningCard(context, topic),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildLearningCard(BuildContext context, Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () {
        final String? routeName = topic['route'] as String?;
        if (routeName != null && routeName.isNotEmpty) {
          Navigator.pushNamed(context, routeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${topic['title']}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ height adjusts to content
          children: [
            // 📸 Image with fixed aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9, // ✅ image always in 16:9 ratio
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: AssetImage(topic['image']),
                    fit: BoxFit.cover, // ✅ no stretch
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(topic['icon'], color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),

            // 📖 Text & actions auto expand
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: topic['color'],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic['description'],
                    style: TextStyle(
                      fontSize: 12,
                      // color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Learn More',
                        style: TextStyle(
                          fontSize: 11,
                          color: topic['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: topic['color'],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
