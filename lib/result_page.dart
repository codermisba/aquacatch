import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

class ResultPage extends StatefulWidget {
  final double annualRainfall;
  final double potentialLiters;
  final String structure;
  final String filterType;
  final String pipeType;
  final double pipeLength;
  final double pipeCost;
  final double filterCost;
  final double installationCost;
  final double totalCost;
  final double savings;
  final int dwellers;
  final double tankCost;
  final double roofArea;
  final double materialCost;
  final double groundwaterLevel;
  final String aquiferType;
  final String city;

  const ResultPage({
    super.key,
    required this.annualRainfall,
    required this.potentialLiters,
    required this.structure,
    required this.filterType,
    required this.pipeType,
    required this.pipeLength,
    required this.pipeCost,
    required this.filterCost,
    required this.installationCost,
    required this.totalCost,
    required this.materialCost,
    required this.savings,
    required this.dwellers,
    required this.tankCost,
    required this.roofArea,
    required this.groundwaterLevel,
    required this.aquiferType,
    required this.city,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final String? hfToken = dotenv.env['HF_TOKEN'];
  final String hfModel = "deepseek-ai/DeepSeek-V3-0324";
  late Future<String> _detailedReportFuture;

  @override
  void initState() {
    super.initState();
    _detailedReportFuture = generateDetailedReport();
  }

  // ---------------- Hugging Face call ----------------
  Future<String> getBotResponseHF(String prompt) async {
    final url = Uri.parse("https://router.huggingface.co/v1/chat/completions");
    final payload = {
      "model": hfModel,
      "messages": [
        {"role": "user", "content": prompt},
      ],
      "temperature": 0.7,
      "max_tokens": 2000,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $hfToken",
          "Content-Type": "application/json",
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

  // ---------------- Generate detailed AI report ----------------
  Future<String> generateDetailedReport() async {
    String prompt =
        """
You are AquaBot, a water harvesting expert. Generate a professional, detailed water harvesting report strictly using the given values. 

 Provided Details (use only these values):
- Annual Rainfall: ${widget.annualRainfall} mm
- Roof Area: ${widget.roofArea} m²
- Potential Water Harvested: ${widget.potentialLiters} L
- Structure Type: ${widget.structure}
- Filter Type: ${widget.filterType}
- Pipe Type: ${widget.pipeType}
- Pipe Length: ${widget.pipeLength} m
- Pipe Cost: ₹${widget.pipeCost.toStringAsFixed(0)}
- Filter Cost: ₹${widget.filterCost.toStringAsFixed(0)}
- Installation Cost: ₹${widget.installationCost.toStringAsFixed(0)}
- Tank cost : ₹${widget.tankCost.toStringAsFixed(0)}
- Material cost : ₹${widget.materialCost.toStringAsFixed(0)}

- Total Cost: ₹${widget.totalCost.toStringAsFixed(0)}
- Expected Savings: ₹${widget.savings.toStringAsFixed(0)} per year
- Number of Dwellers: ${widget.dwellers}
- Groundwater Level: ${widget.groundwaterLevel} m
- Aquifer Type: ${widget.aquiferType}
- City: ${widget.city}

### Instructions for the report:
1. **Use ONLY the given values** for all costs, savings, and dimensions. Do not assume or generate new numeric values.  
2. Format the report in with the following headings:
   -  Overview
   -  Cost Estimation
   -  Water Savings
   -  Groundwater & Soil
   -  Environmental Impact
   -  Recommendations
3. Include a **Cost Estimation Table** comparing filter options if relevant, but use only the provided costs.  
4. Clearly highlight the recommended structure and its benefits.  
5. Provide practical suggestions for maximizing rainwater harvesting efficiency.  
6. Use bullet points, subheadings, and tables where appropriate for clarity.

Strictly adhere to the given values. Do not make assumptions.
""";

    return await getBotResponseHF(prompt);
  }

  // ---------------- Save to Firestore ----------------
  Future<void> saveResultToFirebase(String detailedReport) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final resultData = {
      "annualRainfall": widget.annualRainfall,
      "potentialLiters": widget.potentialLiters,
      "structure": widget.structure,
      "filterType": widget.filterType,
      "pipeType": widget.pipeType,
      "pipeLength": widget.pipeLength,
      "pipeCost": widget.pipeCost,
      "filterCost": widget.filterCost,
      "installationCost": widget.installationCost,
      "totalCost": widget.totalCost,
      "savings": widget.savings,
      "dwellers": widget.dwellers,
      "roofArea": widget.roofArea,
      "groundwaterLevel": widget.groundwaterLevel,
      "aquiferType": widget.aquiferType,
      "city": widget.city,
      "detailedReport": detailedReport,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": user.uid,
    };

    await FirebaseFirestore.instance.collection("results").add(resultData);
  }

  // ---------------- Utility ----------------
  String getStructureLabel() {
    switch (widget.structure.toLowerCase()) {
      case "small":
        return "Small Surface Tank";
      case "medium":
        return "Medium Surface/Underground Tank";
      case "large":
        return "Large Underground Tank";
      default:
        return widget.structure;
    }
  }

  String getStructureImage() {
    switch (widget.structure.toLowerCase()) {
      case "small":
        return "assets/images/small.png";
      case "medium":
        return "assets/images/medium.jpg";
      case "large":
        return "assets/images/large.png";
      default:
        return "assets/images/small.jpg";
    }
  }

  @override
  Widget build(BuildContext context) {
    double annualDemand = widget.dwellers * 135 * 365;
    double arVolume = (widget.potentialLiters > annualDemand)
        ? widget.potentialLiters - annualDemand
        : 0;
    bool arNeeded = arVolume > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Responsive layout
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildRecommendedStructureCard(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCalculationSummaryCard(
                              context,
                              annualDemand,
                              arNeeded,
                              arVolume,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRecommendedStructureCard(context),
                          const SizedBox(height: 16),
                          _buildCalculationSummaryCard(
                            context,
                            annualDemand,
                            arNeeded,
                            arVolume,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Detailed Report
                    FutureBuilder<String>(
                      future: _detailedReportFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text(
                            "Could not generate detailed report.",
                          );
                        }
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Detailed Report",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                MarkdownBody(
                                  data: snapshot.data!,
                                  selectable: true,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        tableColumnWidth:
                                            const IntrinsicColumnWidth(),
                                        tableCellsPadding: const EdgeInsets.all(
                                          6,
                                        ),
                                        p: const TextStyle(fontSize: 14),
                                        h1: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        strong: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text(
                              "Edit Inputs",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text(
                              "Save Report",
                              style: TextStyle(fontSize: 16),
                            ),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              );

                              try {
                                final detailedReport =
                                    await _detailedReportFuture;
                                await saveResultToFirebase(detailedReport);

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Report saved successfully!"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                debugPrint(e.toString());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------- Widgets for cards --------
  Widget _buildRecommendedStructureCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Recommended Structure",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Image.asset(getStructureImage(), height: 150, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(
              getStructureLabel(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSummaryCard(
    BuildContext context,
    double annualDemand,
    bool arNeeded,
    double arVolume,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            _infoRow("Roof Area:", "${widget.roofArea.toStringAsFixed(1)} m²"),
            _infoRow(
              "Annual Rainfall:",
              "${widget.annualRainfall.toStringAsFixed(1)} mm",
            ),
            _infoRow(
              "Potential Harvested Water:",
              "${widget.potentialLiters.toStringAsFixed(1)} L",
            ),
            _infoRow(
              "Annual Water Demand:",
              "${annualDemand.toStringAsFixed(1)} L",
            ),
            _infoRow(
              "AR Needed:",
              arNeeded ? "Yes (${arVolume.toStringAsFixed(1)} L)" : "No",
            ),
            _infoRow(
              "Expected Savings:",
              "₹${widget.savings.toStringAsFixed(0)}",
            ),
            _infoRow("Filter Type:", widget.filterType),
            _infoRow("Pipe Type:", widget.pipeType),
            _infoRow(
              "Pipe Length:",
              "${widget.pipeLength.toStringAsFixed(1)} m",
            ),
            _infoRow("Pipe Cost:", "₹${widget.pipeCost.toStringAsFixed(0)}"),
            _infoRow(
              "Filter Cost:",
              "₹${widget.filterCost.toStringAsFixed(0)}",
            ),
            _infoRow(
              "Material Cost:",
              "₹${widget.materialCost.toStringAsFixed(0)}",
            ),
            _infoRow(
              "Installation Cost:",
              "₹${widget.installationCost.toStringAsFixed(0)}",
            ),
            _infoRow("Tank Cost:", "₹${widget.tankCost.toStringAsFixed(0)}"),
            _infoRow("Total Cost:", "₹${widget.totalCost.toStringAsFixed(0)}"),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cleans Hugging Face Markdown minimally for Flutter UI
String cleanMarkdownForUI(String markdown) {
  return markdown
      // Normalize line endings
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      // Ensure headings start at the first column
      .split('\n')
      .map((line) {
        String trimmed = line.trimRight();
        // Fix divider lines: at least 3 dashes
        if (trimmed.replaceAll('-', '').trim().isEmpty) {
          return '--';
        }
        // Remove zero-width characters Hugging Face may add
        return trimmed.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
      })
      .join('\n')
      // Reduce multiple blank lines
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
