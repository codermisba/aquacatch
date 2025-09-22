import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pdf/pdf.dart';
import 'components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class ResultPage extends StatelessWidget {
  final double annualRainfall;
  final double potentialLiters;
  final String structure;
  final double cost;
  final double savings;
  final int dwellers;
  final double roofArea;
  final double groundwaterLevel;
  final String aquiferType;
  final String city; // optional, can be passed for AI report

  ResultPage({
    super.key,
    required this.annualRainfall,
    required this.potentialLiters,
    required this.structure,
    required this.cost,
    required this.savings,
    required this.dwellers,
    required this.roofArea,
    required this.groundwaterLevel,
    required this.aquiferType,
    this.city = "Unknown City",
  });

  final String? hfToken = dotenv.env['HF_TOKEN'];
  final String hfModel = "deepseek-ai/DeepSeek-V3-0324";

  // ---------------- Hugging Face call ----------------
  Future<String> getBotResponseHF(String prompt) async {
    final url = Uri.parse("https://router.huggingface.co/v1/chat/completions");
    final payload = {
      "model": hfModel,
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "parameters": {"temperature": 0.7, "max_new_tokens": 500}
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $hfToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["choices"] != null && data["choices"].isNotEmpty) {
          return data["choices"][0]["message"]["content"] ?? "No response.";
        }
      } else {
        debugPrint("HF API Error: ${response.statusCode} - ${response.body}");
      }
      return "Could not generate detailed report.";
    } catch (e) {
      return "Error: $e";
    }
  }

  // ---------------- Save to Firestore ----------------
  Future<void> saveResultToFirebase() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Generate detailed report from AI
  String detailedReport = await generateDetailedReport();
  debugPrint(detailedReport);

  final resultData = {
    "annualRainfall": annualRainfall,
    "potentialLiters": potentialLiters,
    "structure": structure,
    "cost": cost,
    "savings": savings,
    "dwellers": dwellers,
    "roofArea": roofArea,
    "groundwaterLevel": groundwaterLevel,
    "aquiferType": aquiferType,
    "city": city,
    "detailedReport": detailedReport, // <-- store AI report
    "timestamp": FieldValue.serverTimestamp(),
    "userId": user.uid,
  };

  await FirebaseFirestore.instance.collection("results").add(resultData);
}


  // ---------------- Generate detailed AI report ----------------
  Future<String> generateDetailedReport() async {
    String prompt = """
You are AquaBot, a water harvesting expert. Generate a detailed water harvesting report for a household with these details:

- Annual Rainfall: ${annualRainfall} mm
- Potential Water Harvested: ${potentialLiters} L
- Structure: ${structure}
- Estimated Cost: ₹${cost}
- Expected Savings: ₹${savings}
- Number of Dwellers: ${dwellers}
- Roof Area: ${roofArea} m²
- Groundwater Level: ${groundwaterLevel} m
- Aquifer Type: ${aquiferType}
- City: ${city}

Include:
- Detailed cost estimation (pipe type, material, labor)
- Water saved
- Average groundwater level and soil type
- Environmental impact
- Structure recommendation

Keep text clear and professional without extra symbols or hashtags.
""";

    return await getBotResponseHF(prompt);
  }

  // ---------------- Generate PDF ----------------
  Future<void> generatePdf() async {
    final pdf = pw.Document();

    final detailedReport = await generateDetailedReport();

    // Load image bytes
    final imageBytes = (await rootBundle.load(getStructureImage()))
        .buffer
        .asUint8List();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Water Harvesting Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Structure: ${getStructureLabel()}'),
              pw.Text('Roof Area: ${roofArea.toStringAsFixed(1)} m²'),
              pw.Text('Annual Rainfall: ${annualRainfall.toStringAsFixed(1)} mm'),
              pw.Text(
                  'Potential Harvested Water: ${potentialLiters.toStringAsFixed(1)} L'),
              pw.Text('Annual Water Demand: ${(dwellers * 135 * 365).toStringAsFixed(1)} L'),
              pw.Text('Estimated Cost: ₹${cost.toStringAsFixed(0)}'),
              pw.Text('Expected Savings: ₹${savings.toStringAsFixed(0)}'),
              pw.Text('Aquifer Type: $aquiferType'),
              pw.Text('Groundwater Level: ${groundwaterLevel.toStringAsFixed(1)} m'),
              pw.SizedBox(height: 16),
              pw.Image(pw.MemoryImage(imageBytes), height: 150),
              pw.SizedBox(height: 16),
              pw.Text('Detailed Analysis:',
                  style:
                      pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(detailedReport),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // ---------------- Utility Methods ----------------
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
    double annualDemand = dwellers * 135 * 365;
    double arVolume = (potentialLiters > annualDemand) ? potentialLiters - annualDemand : 0;
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
            // Recommended Structure Card
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

            // Calculation Summary Card
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
                    _infoRow("Annual Rainfall:", "${annualRainfall.toStringAsFixed(1)} mm"),
                    _infoRow("Potential Harvested Water:", "${potentialLiters.toStringAsFixed(1)} L"),
                    _infoRow("Annual Water Demand:", "${annualDemand.toStringAsFixed(1)} L"),
                    _infoRow("AR Needed:", arNeeded ? "Yes (${arVolume.toStringAsFixed(1)} L)" : "No"),
                    _infoRow("Estimated Cost:", "₹${cost.toStringAsFixed(0)}"),
                    _infoRow("Expected Savings:", "₹${savings.toStringAsFixed(0)}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: textColor),
                    label: const Text(
                      "Edit",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    icon: const Icon(Icons.download, color: textColor),
                    label: const Text(
                      "Save PDF",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator(color: primaryColor)),
                      );

                      try {
                        await saveResultToFirebase();
                        await generatePdf();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("PDF generated & saved successfully!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
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
