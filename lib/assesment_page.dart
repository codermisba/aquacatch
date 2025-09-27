import 'package:flutter/material.dart';
import 'package:aquacatch/rooftop_rainwater_harvesting_form.dart';
import 'package:aquacatch/artificial_recharge_form.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  String? selectedAssessment; // null → no selection yet

  void _navigateToForm() {
    if (selectedAssessment == "Rooftop") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RooftopRainwaterHarvestingForm(),
        ),
      );
    } else if (selectedAssessment == "AR") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ArtificialRechargeForm(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Please select your preferred assessment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Assessment Selection Buttons
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 770,
                ), // same as form width
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedAssessment = "Rooftop";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAssessment == "Rooftop"
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          foregroundColor: selectedAssessment == "Rooftop"
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Rooftop\nRainwater Harvesting",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedAssessment = "AR";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAssessment == "AR"
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          foregroundColor: selectedAssessment == "AR"
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Artificial\nRecharge (AR)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If no selection yet
            if (selectedAssessment == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "Choose an assessment from above to start the form.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
              )
            else
              _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  selectedAssessment == "Rooftop"
                      ? "Rainwater Harvesting Assessment"
                      : "Artificial Recharge Assessment",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  selectedAssessment == "Rooftop"
                      ? "Assess your rooftop's potential for rainwater harvesting and get detailed cost estimates."
                      : "Evaluate artificial recharge potential for groundwater replenishment with cost analysis.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Start ${selectedAssessment == "Rooftop" ? "Rooftop" : "AR"} Assessment",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _navigateToForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
