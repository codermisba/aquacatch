import 'package:flutter/material.dart';
import 'components.dart';

class ResultPage extends StatelessWidget {
  final double rainfall;
  final double potentialLiters;
  final String structure;
  final double cost;
  final double savings;

  const ResultPage({
    super.key,
    required this.rainfall,
    required this.potentialLiters,
    required this.structure,
    required this.cost,
    required this.savings,
  });

  // Map-based image loader
  Widget showStructureImage(String structure) {
    Map<String, String> images = {
      "Small tank on rooftop": "images/small.jpg",
      "Medium-sized surface tank": "images/medium.jpg",
      "Large underground tank": "images/large.jpg",
    };

    String? imagePath = images[structure];
    if (imagePath == null) return const SizedBox(); // No image

    return Builder(builder: (context) {
      precacheImage(AssetImage(imagePath), context);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imagePath, height: 180, fit: BoxFit.cover),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Report Header -----
            Container(
              decoration: BoxDecoration(
                // gradient: LinearGradient(
                //   colors: [Color(0xFF257ca3), Color(0xFFa2d2df)],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
                color: Color(0xFF107dac),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("Rainwater Harvesting Assessment",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    "Detailed report of harvesting potential, recommended structures, and cost estimates",
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white70, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ----- Rainfall & Harvesting Potential -----
            _buildReportSection("Estimated Annual Rainfall",
                "${rainfall.toStringAsFixed(2)} mm", Colors.blue),
            const SizedBox(height: 12),
            _buildReportSection("Estimated Harvesting Potential",
                "${potentialLiters.toStringAsFixed(0)} liters/year", Colors.green),
            const SizedBox(height: 12),
            _buildReportSection(
                "Estimated Cost", "₹${cost.toStringAsFixed(0)}", Colors.orange),
            const SizedBox(height: 12),
            _buildReportSection("Estimated Annual Savings",
                "₹${savings.toStringAsFixed(2)}", Colors.purple),
            const SizedBox(height: 25),

            // ----- Recommended Structure -----
            const Text(
              "Recommended Structure",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    structure,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 15),
                  showStructureImage(structure),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ----- Buttons -----
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement download functionality
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label:
                        const Text("Download", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      shadowColor: Colors.grey.shade400,
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Edit", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3c8baa),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      shadowColor: Colors.grey.shade400,
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
