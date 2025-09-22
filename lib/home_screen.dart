import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components.dart';
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
      waterSaved = latestWaterSaved; // show water saved instead of past assessments
    });

    print("Reports: $reportCount, Water Saved: $latestWaterSaved");
  } catch (e) {
    print("Error fetching counts: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [ SingleChildScrollView(
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
              child: const Text(
                "Learn More About Rainwater Harvesting",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 25),
            _buildLearningCards(context),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                "Important links",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 40,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Central Ground Water Board (CGWB)",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => _launchURL('https://www.jalshakti-dowr.gov.in/'),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.water_drop, size: 40, color: Colors.teal),
                            SizedBox(height: 8),
                            Text(
                              "Ministry of Jal Shakti.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                        
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
          ],
        ),
        
        
      ),
       Positioned(
      bottom: 20,
      right: 20,
      child: _buildChatbotButton(),
    ),
      ],
    );

  }

//chatbot button
bool _showTooltip = true;

Widget _buildChatbotButton() {
  // Hide tooltip after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted && _showTooltip) {
      setState(() {
        _showTooltip = false;
      });
    }
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AnimatedOpacity(
        opacity: _showTooltip ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: const Text(
            "Hello I am AquaBot, Have a question? Ask me!",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.chat, color: Colors.white,),
        onPressed: () {
          Navigator.pushNamed(context, '/chat'); // Your chat page route
        },
      ),
    ],
  );
}

  // ---------------- Top Section ----------------
  Widget _buildTopSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox(
              "Water Saved (L)",
              "${waterSaved.toStringAsFixed(1)}",
              Icons.water_drop,
              Colors.blue,
            ),
            _buildStatBox(
              "Reports",
              "$reportCount",
              Icons.description,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
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
        'image': '/assets/images/small.jpg',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'route': '/rainwater_harvesting',
      },
      {
        'title': 'Artificial Recharge',
        'description':
            'Discover methods to artificially recharge groundwater aquifers',
        'image': '/assets/images/artificial_recharge.png',
        'icon': Icons.layers,
        'color': Colors.green,
        'route': '/artifitial_recharge',
      },
      {
        'title': 'Rooftop Rain Water Harvesting',
        'description':
            'Explore techniques for collecting rainwater from building rooftops',
        'image': '/assets/images/rtrwh.png',
        'icon': Icons.home,
        'color': Colors.orange,
        'route': '/rooftop_rainwaterharvesting',
      },
      {
        'title': 'Why Fresh Water Matters',
        'description':
            'Fresh water plays a vital role in replenishing underground aquifers. It helps maintain soil permeability and ensures that groundwater remains a sustainable resource for communities and ecosystems.',
        'image': '/assets/images/fresh_water.png',
        'icon': Icons.terrain,
        'color': Colors.brown,
        'route': '/fresh_water',
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLearningCard(context, learningTopics[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildLearningCard(context, learningTopics[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLearningCard(context, learningTopics[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildLearningCard(context, learningTopics[3])),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
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
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topic['color'].withOpacity(0.1),
                topic['color'].withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(topic['image']),
                    fit: BoxFit.cover,
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
              Expanded(
                child: Padding(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          topic['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
