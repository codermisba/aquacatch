import 'package:flutter/material.dart';
import 'components.dart';
import 'assesment_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatelessWidget {
  final List<String> imageUrls = [
    "https://cdn1.byjus.com/wp-content/uploads/2023/05/Rainwater-harvesting-1.png",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/RWH-image.jpg/800px-RWH-image.jpg"
  ];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                MaterialPageRoute(builder: (context) => const ProfilePage()),
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
            _buildInfoCards(context),
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
              // decoration: BoxDecoration(
              //   color: primaryColor.withOpacity(0.1),
              //   borderRadius: BorderRadius.circular(30),
              //   border: Border.all(color: primaryColor, width: 2),
              // ),
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
    );
  }

  // ---------------- Info Cards ----------------
  Widget _buildInfoCards(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildCard("Past Assessments", Icons.history, Colors.blue),
        _buildCard("Reports", Icons.description, Colors.green),
        _buildCard("No. of Statements", Icons.analytics, Colors.orange),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.grey.shade300,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
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
          children: steps
              .map(
                (step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(step,
                            style: const TextStyle(fontSize: 16, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
