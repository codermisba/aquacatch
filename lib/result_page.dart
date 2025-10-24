import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
//import 'package:flutter_markdown/flutter_markdown.dart';
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
  // final double totalCost;
  final double requiredTankCapacityLiters;
  final double savings;
  final int dwellers;
  final double roofArea;
  final double materialCost;
  final double groundwaterLevel;
  final String aquiferType;
  final String city;
  final double plasticTankCost;
  final double concreteTankCost;
  final String concreteDimensions;
  final double totalCostPlastic;
  final double totalCostConcrete;
  final String locationType;
  final double annualwaterDemand;
  final double dailyWaterDemand;

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
    required this.materialCost,
    required this.savings,
    required this.dwellers,
    required this.roofArea,
    required this.groundwaterLevel,
    required this.aquiferType,
    required this.city,
    required this.plasticTankCost,
    required this.concreteTankCost,
    required this.concreteDimensions,
    required this.totalCostPlastic,
    required this.totalCostConcrete,
    required this.requiredTankCapacityLiters,
    required this.locationType,
    required this.annualwaterDemand,
    required this.dailyWaterDemand,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  
  late Future<String> _detailedReportFuture;

  @override
  void initState() {
    super.initState();
    _detailedReportFuture = Future.value(
      generateReportTemplate({
        'city': widget.city,
        'groundwaterLevel': widget.groundwaterLevel,
        'aquiferType': widget.aquiferType,
        'annualRainfall': widget.annualRainfall,
        'roofArea': widget.roofArea,
        'potentialLiters': widget.potentialLiters,
        'dwellers': widget.dwellers,
        'structure': widget.structure,
        'concreteDimensions': widget.concreteDimensions,
        "plasticTankCost": widget.plasticTankCost,
        "concreteTankCost": widget.concreteTankCost,
        "totalCostPlastic": widget.totalCostPlastic,
        "totalCostConcrete": widget.totalCostConcrete,
        'pipeType': widget.pipeType,
        'pipeCost': widget.pipeCost,
        'filterType': widget.filterType,
        'filterCost': widget.filterCost,
        'installationCost': widget.installationCost,
        'savings': widget.savings,
        'AnnualwaterDemand': widget.annualwaterDemand,
        'dailyWaterDemand' : widget.dailyWaterDemand,
        'locationType' : widget.locationType,
        
      }),
    );
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
      "savings": widget.savings,
      "dwellers": widget.dwellers,
      "roofArea": widget.roofArea,
      "groundwaterLevel": widget.groundwaterLevel,
      "aquiferType": widget.aquiferType,
      "city": widget.city,
      "requiredTankCapacityLiters": widget.requiredTankCapacityLiters,
      "plasticTankCost": widget.plasticTankCost,
      "concreteTankCost": widget.concreteTankCost,
      "concreteDimensions": widget.concreteDimensions,
      "totalCostPlastic": widget.totalCostPlastic,
      "totalCostConcrete": widget.totalCostConcrete,
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
    final imageBytes = (await rootBundle.load(
      getStructureImage(),
    )).buffer.asUint8List();
    final structureImage = pw.MemoryImage(imageBytes);

    // Utility to clean Markdown formatting
    String cleanMarkdown(String line) {
      line = line.replaceAll(RegExp(r'^#+\s*'), '');
      line = line.replaceAll(RegExp(r'\*\*'), '');
      line = line.replaceAll(RegExp(r'\*'), '');
      return line.trim();
    }

    bool isTableLine(String line) => line.startsWith('|') && line.endsWith('|');

    bool isTableSeparatorLine(String line) =>
        line.replaceAll('|', '').trim().replaceAll('-', '').isEmpty;

    List<List<String>> parseTable(List<String> lines) {
      final filteredLines = lines
          .where((l) => !isTableSeparatorLine(l))
          .toList();
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
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                cleanMarkdown(line),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
              ),
            ),
          );
        } else if (line.startsWith('## ')) {
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                cleanMarkdown(line),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
              ),
            ),
          );
        } else if (line.startsWith('### ')) {
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                cleanMarkdown(line),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
              ),
            ),
          );
        } else if (line.startsWith('- ')) {
          widgets.add(
            pw.Bullet(
              text: cleanMarkdown(line),
              style: pw.TextStyle(font: ttf),
            ),
          );
        } else {
          widgets.add(
            pw.Text(
              cleanMarkdown(line),
              style: pw.TextStyle(fontSize: 12, font: ttf),
            ),
          );
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
            child: pw.Text(
              'Rainwater Harvesting Analysis',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // Subheading for Recommended Structure
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Recommended Structure',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
              ),
            ),
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
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
        return widget.structure; // fallback
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
    double annualDemand = widget.annualwaterDemand;
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
                        // color: Colors.grey[800],
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
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
                    _infoRow(
                      "Area Type:",
                      widget.locationType,
                    ),
                    _infoRow(
                      "Roof Area:",
                      "${widget.roofArea.toStringAsFixed(1)} m²",
                    ),
                    _infoRow(
                      "Annual Rainfall:",
                      "${widget.annualRainfall.toStringAsFixed(1)} mm",
                    ),
                    _infoRow(
                      "Potential Harvested Water:",
                      "${widget.potentialLiters.toStringAsFixed(1)} L",
                    ),
                    _infoRow(
                      "Daily Water Demand L/Person :",
                      "${widget.dailyWaterDemand.toStringAsFixed(1)} L",
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
                    _infoRow(
                      "Pipe Cost:",
                      "₹${widget.pipeCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Filter Cost:",
                      "₹${widget.filterCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Material Cost:",
                      "₹${widget.materialCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Required Tank Capacity(Litre)",
                      "${widget.requiredTankCapacityLiters.toStringAsFixed(0)}L",
                    ),
                    _infoRow(
                      "Installation Cost:",
                      "₹${widget.installationCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Plastic Tank cost:",
                      "₹${widget.plasticTankCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Concrete Tank Cost:",
                      "₹${widget.concreteTankCost.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Total Cost for Plastic Tank:",
                      "₹${widget.totalCostPlastic.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Total Cost For Concrete Tank:",
                      "₹${widget.totalCostConcrete.toStringAsFixed(0)}",
                    ),
                    _infoRow(
                      "Dimensions For Concrete Tank:",
                      "${widget.concreteDimensions}(LxWxH)",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _detailedReportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Could not generate detailed report.");
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
                                tableColumnWidth: const IntrinsicColumnWidth(),
                                tableCellsPadding: const EdgeInsets.all(6),
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

            // Buttons
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
                        final detailedReport = generateReportTemplate({
                          'city': widget.city,
                          'groundwaterLevel': widget.groundwaterLevel,
                          'aquiferType': widget.aquiferType,
                          'annualRainfall': widget.annualRainfall,
                          'roofArea': widget.roofArea,
                          'potentialLiters': widget.potentialLiters,
                          'dwellers': widget.dwellers,
                          'structure': widget.structure,
                          'concreteDimensions': widget.concreteDimensions,
                          "plasticTankCost": widget.plasticTankCost,
                          "concreteTankCost": widget.concreteTankCost,
                          "totalCostPlastic": widget.totalCostPlastic,
                          "totalCostConcrete": widget.totalCostConcrete,
                          'pipeType': widget.pipeType,
                          'pipeCost': widget.pipeCost,
                          'filterType': widget.filterType,
                          'filterCost': widget.filterCost,
                          'installationCost': widget.installationCost,
                          'savings': widget.savings,
                          'AnnualwaterDemand': annualDemand,
                          'locationType':widget.locationType,
                          'dailyWaterDemand' : widget.dailyWaterDemand,
                        });

                        // await _detailedReportFuture; // reuse the existing report
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

String generateReportTemplate(Map<String, dynamic> data) {
  return '''
# Rainwater Harvesting System Report

---

## 1. Location and Site Details
**City:** ${data['city']}  
**Location Type:** ${data['locationType']}  
**Groundwater Level:** ${data['groundwaterLevel']}  
**Aquifer Type:** ${data['aquiferType']}  

---

## 2. Rainfall and Catchment Information
**Annual Rainfall:** ${data['annualRainfall']} mm  
**Roof Catchment Area:** ${data['roofArea']} m²  
**Estimated Water Harvested:** ${data['potentialLiters']} L/year  
**Estimated Water Demand:** ${data['annualwaterDemand']} L/year  
**Daily Water Demand per Person:** ${data['dailyWaterDemand']} L  
**Number of Dwellers:** ${data['dwellers']}  

> Based on local rainfall and available roof area, the estimated annual harvestable water is approximately **${(data['potentialLiters'] / 1000).toStringAsFixed(2)} kiloliters**.

---

## 3. Tank Design and Capacity Details
**Required Tank Capacity:** ${data['requiredTankCapacityLiters']} L  
**Recommended Structure Type:** ${data['structure']}  
**Concrete Tank Dimensions:** ${data['concreteDimensions']}  
**Plastic Tank Cost:** ₹${data['plasticTankCost']}  
**Concrete Tank Cost:** ₹${data['concreteTankCost']}  

> The recommended tank capacity provides sufficient storage for approximately **30 days of domestic consumption** based on rainfall and water demand.

---

## 4. Components and Cost Estimation

| Component | Type/Details | Cost (₹) |
|------------|--------------|----------:|
| Pipes | ${data['pipeType']} | ${data['pipeCost']} |
| Filter | ${data['filterType']} | ${data['filterCost']} |
| Installation | — | ${data['installationCost']} |
| Material (Misc.) | — | ${data['materialCost']} |
| **Total Cost (Plastic System)** |  | **₹${data['totalCostPlastic']}** |
| **Total Cost (Concrete System)** |  | **₹${data['totalCostConcrete']}** |

---

## 5. Savings and Economic Analysis
**Estimated Annual Savings:** ₹${data['savings']}  
**Approximate Payback Period:** ${(data['totalCostConcrete'] / (data['savings'] + 1)).toStringAsFixed(1)} years  

> Implementing a rainwater harvesting system can significantly reduce dependency on municipal supply, lower annual water expenditure, and support groundwater recharge.

---

## 6. Recommendations
- For **${data['locationType']}** areas, a **${data['structure']}** tank structure is recommended.  
- Ensure regular maintenance of the **roof catchment** and **first-flush filter systems** before each monsoon.  
- Incorporate **overflow management** and **groundwater recharge pits** where feasible.  
- Use harvested rainwater for **non-potable purposes** such as cleaning, gardening, and toilet flushing.  

---

## 7. Summary of Design Parameters

| Parameter | Value |
|------------|-------:|
| Annual Rainfall (mm) | ${data['annualRainfall']} |
| Roof Catchment Area (m²) | ${data['roofArea']} |
| Tank Capacity (L) | ${data['requiredTankCapacityLiters']} |
| Annual Water Demand (L) | ${data['annualwaterDemand']} |
| Estimated Harvest (L) | ${data['potentialLiters']} |
| Annual Savings (₹) | ${data['savings']} |

---

**Note:**  
This report is generated using rainfall data, design parameters, and calculation principles derived from the *“Design of Rainwater Harvesting Water Tank”* methodology.

''';
}
 