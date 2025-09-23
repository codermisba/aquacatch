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
import 'components.dart';

class ResultPage extends StatefulWidget {
  final double annualRainfall;
  final double potentialLiters;
  final String structure;
  final double cost;
  final double savings;
  final int dwellers;
  final double roofArea;
  final double groundwaterLevel;
  final String aquiferType;
  final String city;

  const ResultPage({
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
        {"role": "user", "content": prompt}
      ],
      "parameters": {"temperature": 0.7, "max_new_tokens": 600}
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

  // ---------------- Generate detailed AI report ----------------
  Future<String> generateDetailedReport() async {
    String prompt = """
You are AquaBot, a water harvesting expert. Generate a professional, detailed water harvesting report for a household with these details:

- Annual Rainfall: ${widget.annualRainfall} mm
- Potential Water Harvested: ${widget.potentialLiters} L
- Structure: ${widget.structure}
- Number of Dwellers: ${widget.dwellers}
- Roof Area: ${widget.roofArea} m²
- Groundwater Level: ${widget.groundwaterLevel} m
- Aquifer Type: ${widget.aquiferType}
- City: ${widget.city}

### Instructions:
1. Calculate estimated costs dynamically based on the structure type and size.
2. Suggest expected savings (₹ per year).
3. Generate a comparison **Cost Estimation Table** for different filter options, including:
   - Structure Type
   - Approx. Cost (₹)
   - Expected Lifespan
   - Maintenance Level
4. Recommend the most cost-effective option for this case.

Use markdown headings:
- Overview
- Cost Estimation
- Water Savings
- Groundwater & Soil
- Environmental Impact
- Recommendations
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
      "cost": widget.cost,
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

  

Future<void> generatePdf(String detailedReport) async {
  final pdf = pw.Document();

  final ttf = await PdfGoogleFonts.nunitoRegular();

  // Load structure image
  final imageBytes = (await rootBundle.load(getStructureImage()))
      .buffer
      .asUint8List();
  final structureImage = pw.MemoryImage(imageBytes);

  // Utility to clean Markdown formatting
  String cleanMarkdown(String line) {
    line = line.replaceAll(RegExp(r'^#+\s*'), '');
    line = line.replaceAll(RegExp(r'\*\*'), '');
    line = line.replaceAll(RegExp(r'\*'), '');
    return line.trim();
  }

  bool isTableLine(String line) => line.startsWith('|') && line.endsWith('|');

  bool isTableSeparatorLine(String line) => line.replaceAll('|', '').trim().replaceAll('-', '').isEmpty;

  List<List<String>> parseTable(List<String> lines) {
    final filteredLines = lines.where((l) => !isTableSeparatorLine(l)).toList();
    return filteredLines.map((line) {
      return line
          .split('|')
          .map((cell) => cell.replaceAll(RegExp(r'\*\*'), '').trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
    }).toList();
  }

  pw.Widget buildTable(List<List<String>> rows) {
    return pw.Table.fromTextArray(
      headers: rows.first,
      data: rows.sublist(1),
      cellStyle: pw.TextStyle(fontSize: 12, font: ttf),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
      border: pw.TableBorder.all(),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  List<pw.Widget> buildMarkdownWidgets(String markdown) {
    final lines = markdown.split('\n');
    final widgets = <pw.Widget>[];
    final tableBuffer = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        if (tableBuffer.isNotEmpty) {
          widgets.add(buildTable(parseTable(tableBuffer)));
          tableBuffer.clear();
        }
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      if (line.startsWith('---') || line.startsWith('--')) {
        widgets.add(pw.Divider());
        continue;
      }

      if (isTableLine(line)) {
        tableBuffer.add(line);
        continue;
      } else if (tableBuffer.isNotEmpty) {
        widgets.add(buildTable(parseTable(tableBuffer)));
        tableBuffer.clear();
      }

      if (line.startsWith('# ')) {
        widgets.add(pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(cleanMarkdown(line),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttf)),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(cleanMarkdown(line),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf)),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(cleanMarkdown(line),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttf)),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(pw.Bullet(text: cleanMarkdown(line), style: pw.TextStyle(font: ttf)));
      } else {
        widgets.add(pw.Text(cleanMarkdown(line), style: pw.TextStyle(fontSize: 12, font: ttf)));
      }
    }

    if (tableBuffer.isNotEmpty) {
      widgets.add(buildTable(parseTable(tableBuffer)));
    }

    return widgets;
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) => [
        // Main Heading
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('Rainwater Harvesting Analysis',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttf)),
        ),
        pw.SizedBox(height: 16),

        // Subheading for Recommended Structure
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('Recommended Structure',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf)),
        ),
        pw.SizedBox(height: 8),

        // Structure image
        pw.Center(child: pw.Image(structureImage, height: 150)),

        pw.SizedBox(height: 16),

        // Rest of report
        ...buildMarkdownWidgets(detailedReport),
      ],
    ),
  );

  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}




  // ---------------- Utility ----------------
  String getStructureLabel() {
    switch (widget.structure.toLowerCase()) {
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
    switch (widget.structure.toLowerCase()) {
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
    double annualDemand = widget.dwellers * 135 * 365;
    double arVolume = (widget.potentialLiters > annualDemand) ? widget.potentialLiters - annualDemand : 0;
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
                    Text("Recommended Structure",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    const SizedBox(height: 12),
                    Image.asset(getStructureImage(),
                        height: 150, fit: BoxFit.contain),
                    const SizedBox(height: 12),
                    Text(getStructureLabel(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
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
                    const Text("Calculation Summary",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 12),
                    _infoRow("Roof Area:", "${widget.roofArea.toStringAsFixed(1)} m²"),
                    _infoRow("Annual Rainfall:", "${widget.annualRainfall.toStringAsFixed(1)} mm"),
                    _infoRow("Potential Harvested Water:", "${widget.potentialLiters.toStringAsFixed(1)} L"),
                    _infoRow("Annual Water Demand:", "${annualDemand.toStringAsFixed(1)} L"),
                    _infoRow("AR Needed:", arNeeded ? "Yes (${arVolume.toStringAsFixed(1)} L)" : "No"),
                    _infoRow("Estimated Cost:", "₹${widget.cost.toStringAsFixed(0)}"),
                    _infoRow("Expected Savings:", "₹${widget.savings.toStringAsFixed(0)}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Report (Markdown)
            FutureBuilder<String>(
              future: _detailedReportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: primaryColor)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Could not generate detailed report.");
                }
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Detailed Report",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor)),
                        const SizedBox(height: 12),
                        MarkdownBody(
                          data: snapshot.data!,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            tableColumnWidth: const IntrinsicColumnWidth(),
                            tableCellsPadding: const EdgeInsets.all(6),
                            p: const TextStyle(fontSize: 14, color: Colors.black87),
                            h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            strong: const TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: textColor),
                    label: const Text("Edit",
                        style: TextStyle(color: textColor, fontSize: 16)),
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
                    label: const Text("Save Report",
                        style: TextStyle(color: textColor, fontSize: 16)),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                            child: CircularProgressIndicator(color: primaryColor)),
                      );

                      try {
                        final detailedReport = await _detailedReportFuture; // reuse the existing report
    await saveResultToFirebase(detailedReport);
    await generatePdf(detailedReport); // pass it here

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
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }
}
