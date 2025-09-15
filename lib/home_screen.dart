import 'package:aquacatch/main.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'components.dart';
import 'assesment_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> imageUrls = [
    "https://cdn1.byjus.com/wp-content/uploads/2023/05/Rainwater-harvesting-1.png",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/RWH-image.jpg/800px-RWH-image.jpg"
  ];

  DateTime? lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
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
        backgroundColor: primaryColor,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 28, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => ProfilePage(
                  setLocale: (locale) {
                    MyApp.setLocale(context, locale);
                  },
                ),
              ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopSection(context),
            const SizedBox(height: 25),

            // Get Started Button
            customButton("Get Started", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AssessmentPage()),
              );
            }),
            const SizedBox(height: 40),

            // Know More Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                "Know More",
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

            _buildLogoPlaceholders(),
            const SizedBox(height: 20),

            _buildCGWBLinkCard(), // ✅ moved here after logos
            const SizedBox(height: 30),

            _buildAboutSection(),
            const SizedBox(height: 30),

            _buildArtificialRechargeSection(),
            const SizedBox(height: 30),

            _buildImageGallery(),
            const SizedBox(height: 30),

            _buildUsageSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }

  // ---------------- Top Section ----------------
  Widget _buildTopSection(BuildContext context) {
    return Column(
      children: [
        // Quick Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatBox("Past Assessments", "12", Icons.history, Colors.blue),
            _buildStatBox("Reports", "5", Icons.description, Colors.green),
          ],
        ),
        const SizedBox(height: 20),

        // Graph Section
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Water Saved (Liters)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text("Jan");
                                case 1:
                                  return const Text("Feb");
                                case 2:
                                  return const Text("Mar");
                                case 3:
                                  return const Text("Apr");
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: 50, color: Colors.blue, width: 18)
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: 80, color: Colors.blue, width: 18)
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(toY: 100, color: Colors.blue, width: 18)
                        ]),
                        BarChartGroupData(x: 3, barRods: [
                          BarChartRodData(toY: 60, color: Colors.blue, width: 18)
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Logo Placeholders ----------------
  Widget _buildLogoPlaceholders() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                Icon(Icons.account_balance, size: 40, color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  "Central Ground Water Board (CGWB) manages India's groundwater scientifically and sustainably.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                Icon(Icons.water_drop, size: 40, color: Colors.teal),
                SizedBox(height: 8),
                Text(
                  "Ministry of Jal Shakti oversees water resources and promotes rainwater harvesting across India.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- CGWB Link Card ----------------
  Widget _buildCGWBLinkCard() {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse("https://cgwb.gov.in/");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        color: accentColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: const [
              Icon(Icons.public, size: 40, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Visit Central Ground Water Board (CGWB) →",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- About Section ----------------
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "What is Rainwater Harvesting?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          "Rainwater Harvesting (RWH) is the practice of collecting and storing rainwater for "
          "future use, reducing dependency on groundwater and municipal supply.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        SizedBox(height: 15),
        Text(
          "Rooftop Rainwater Harvesting",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Collecting rainwater from rooftops is an effective way to capture water. "
          "It can be stored in tanks, ponds, or used for irrigation, reducing municipal water usage.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  // ---------------- Artificial Recharge Section ----------------
  Widget _buildArtificialRechargeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Artificial Recharge of Groundwater",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          "Artificial recharge refers to the process of augmenting the natural infiltration of rainwater into the ground. "
          "Methods include percolation tanks, recharge pits, injection wells, and check dams. "
          "It helps replenish groundwater levels and ensures sustainable water supply.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  // ---------------- Image Gallery ----------------
  Widget _buildImageGallery() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imageUrls.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- How to Use ----------------
  Widget _buildUsageSection() {
    final steps = [
      "Click on 'Get Started'.",
      "Fill in your location details including city and pincode.",
      "Enter roof area, roof type, and available open space accurately.",
      "Specify number of dwellers and water consumption patterns.",
      "Submit the form to generate recommendations.",
      "View the results with suitable RWH structure suggestions.",
      "Download the assessment report in PDF format.",
      "Edit the details anytime to update recommendations.",
      "Follow suggested measures for efficient water conservation.",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How to Use the AquaCatch App?",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: steps.asMap().entries.map((entry) {
            int index = entry.key + 1;
            String step = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryColor,
                    child: Text(
                      "$index",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(step,
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
