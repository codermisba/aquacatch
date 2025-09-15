import 'package:flutter/material.dart';
import 'components.dart';

class ResultPage extends StatelessWidget {
  final double annualRainfall;
  final double potentialLiters;
  final String structure;
  final double cost;
  final double savings;
  final int dwellers;
  final double roofArea;

  const ResultPage({
    super.key,
    required this.annualRainfall,
    required this.potentialLiters,
    required this.structure,
    required this.cost,
    required this.savings,
    required this.dwellers,
    required this.roofArea,
  });

  // Map structure labels
  String getStructureLabel() {
    switch (structure.toLowerCase()) {
      case "small tank on rooftop":
        return "Small Rooftop Tank";
      case "medium-sized surface tank":
        return "Medium Surface Tank";
      case "large underground tank":
        return "Large Underground Tank";
      default:
        return "No Harvesting Needed";
    }
  }

  // Map structure images
  String getStructureImage() {
    switch (structure.toLowerCase()) {
      case "small tank on rooftop":
        return "assets/images/small.jpg";
      case "medium-sized surface tank":
        return "assets/images/medium.jpg";
      case "large underground tank":
        return "assets/images/large.jpg";
      default:
        return "assets/images/no_harvesting.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    double annualDemand = dwellers * 135 * 365; // 135 L per day per dweller
    double arVolume = (potentialLiters > annualDemand)
        ? potentialLiters - annualDemand
        : 0;
    bool arNeeded = arVolume > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recommended Structure
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Recommended Structure",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      getStructureImage(),
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      getStructureLabel(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Calculation Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Calculation Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow("Roof Area:", "${roofArea.toStringAsFixed(1)} m²"),
                    _infoRow(
                      "Annual Rainfall:",
                      "${annualRainfall.toStringAsFixed(1)} mm",
                    ),
                    _infoRow(
                      "Potential Harvested Water:",
                      "${potentialLiters.toStringAsFixed(1)} L",
                    ),
                    _infoRow(
                      "Annual Water Demand:",
                      "${annualDemand.toStringAsFixed(1)} L",
                    ),
                    _infoRow(
                      "AR Needed:",
                      arNeeded
                          ? "Yes (${arVolume.toStringAsFixed(1)} L)"
                          : "No",
                    ),
                    _infoRow("Estimated Cost:", "₹${cost.toStringAsFixed(0)}"),
                    _infoRow(
                      "Expected Savings:",
                      "₹${savings.toStringAsFixed(0)}",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Graphs: Annual Water & Money Savings (stacked vertically)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Annual Savings",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Water Savings
                    Row(
                      children: [
                        const Text(
                          "Water:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    1, // 100% of the available width (can scale)
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${potentialLiters.toStringAsFixed(1)} L",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Money Savings
                    Row(
                      children: [
                        const Text(
                          "Money:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    1, // scale proportionally if needed
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹${savings.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Edit & Download Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: textColor,),
                    label: const Text("Edit",style: TextStyle(color: textColor, fontSize: 16),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Go back to assessment page
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download,color: textColor,),
                    label: const Text("Download",style:TextStyle(color: textColor, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                    onPressed: () {
                      // TODO: Implement download / PDF export
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
