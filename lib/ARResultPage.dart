import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ARResultPage extends StatefulWidget {
  final String district;
  final double rrwhPotential;
  final double arPotential;
  final String soilType;
  final double porosity;
  final double evaporation;
  final double groundwaterLevel;
  final double annualRainfall;
  final Map<String, dynamic>? arStructure;
  final dynamic pipeType;
  final dynamic pipeSize;
  final double? arTotalCost;
  final double? arMaxCost;
  final double roofArea;
  final String roofMaterial;
  final Map<String, dynamic>? fullDistrictData;

  const ARResultPage({
    super.key,
    required this.district,
    required this.rrwhPotential,
    required this.arPotential,
    required this.soilType,
    required this.porosity,
    required this.evaporation,
    required this.groundwaterLevel,
    required this.annualRainfall,
    required this.arStructure,
    required this.pipeType,
    required this.pipeSize,
    required this.arTotalCost,
    required this.arMaxCost,
    required this.roofArea,
    required this.roofMaterial,
    required this.fullDistrictData,
  });

  @override
  State<ARResultPage> createState() => _ARResultPageState();
}

class _ARResultPageState extends State<ARResultPage> {
  late Future<String> _detailedReportFuture;

  @override
  void initState() {
    super.initState();
    _detailedReportFuture = Future.value(
      generateARReportTemplate(),
    );
  }

  // ---------------- FIREBASE SAVE ----------------
  Future<void> saveResultToFirebase(String report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("ar_results").add({
      "district": widget.district,
      "annualRainfall": widget.annualRainfall,
      "roofArea": widget.roofArea,
      "rrwhPotential": widget.rrwhPotential,
      "arPotential": widget.arPotential,
      "soilType": widget.soilType,
      "porosity": widget.porosity,
      "groundwaterLevel": widget.groundwaterLevel,
      "structure": widget.arStructure,
      "pipeType": widget.pipeType,
      "pipeSize": widget.pipeSize,
      "totalCost": widget.arTotalCost,
      "detailedReport": report,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": user.uid,
    });
  }

  // ---------------- PDF GENERATION ----------------
  Future<void> generatePdf(String report) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          pw.Text(
            "Artificial Recharge Report",
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            report.replaceAll(RegExp(r'[#*]'), ''),
            style: pw.TextStyle(fontSize: 12, font: font),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ---------------- MARKDOWN REPORT ----------------
  String generateARReportTemplate() {
    final s = widget.arStructure ?? {};

    return '''
# Artificial Recharge (AR) System Report

---

## 1. Location Details
**District:** ${widget.district}  
**Soil Type:** ${widget.soilType}  
**Porosity:** ${widget.porosity}  
**Groundwater Level:** ${widget.groundwaterLevel} m  

---

## 2. Rainfall & Catchment
**Annual Rainfall:** ${widget.annualRainfall} mm  
**Roof Area:** ${widget.roofArea} m²  
**RRWH Potential:** ${widget.rrwhPotential} m³/year  
**Rechargeable Water:** ${widget.arPotential} m³/year  

---

## 3. Recommended Recharge Structure
**Structure Name:** ${s['structure_name'] ?? 'N/A'}  
**Depth:** ${s['depth'] ?? 'N/A'} m  
**Diameter:** ${s['diameter'] ?? 'N/A'} m  
**Recharge Rate:** ${s['recharge_rate'] ?? 'N/A'} m³/day  
**Suitable Soil:** ${s['suitable_soil'] ?? 'N/A'}  

---

## 4. Conveyance System
**Pipe Type:** ${widget.pipeType}  
**Pipe Size:** ${widget.pipeSize}  

---

## 5. Cost Estimation
**Estimated Implementation Cost:** ₹${widget.arTotalCost?.toStringAsFixed(0)}  

---

## 6. Benefits
- Improves groundwater sustainability  
- Reduces surface runoff  
- Enhances aquifer recharge  

---

## 7. Summary Table

| Parameter | Value |
|---------|-------|
| Annual Rainfall (mm) | ${widget.annualRainfall} |
| AR Potential (m³/year) | ${widget.arPotential} |
| Structure | ${s['structure_name'] ?? 'N/A'} |
| Estimated Cost (₹) | ${widget.arTotalCost?.toStringAsFixed(0)} |

---

**Note:**  
This report is generated using standard artificial recharge design guidelines.
''';
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AR Report", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard(),
            const SizedBox(height: 16),
            _detailedReportCard(),
            const SizedBox(height: 20),
            _actionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final s = widget.arStructure ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Artificial Recharge Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow("District:", widget.district),
            _infoRow("Soil Type:", widget.soilType),
            _infoRow("Annual Rainfall:", "${widget.annualRainfall} mm"),
            _infoRow("Recharge Potential:", "${widget.arPotential} m³/year"),
            _infoRow("Structure:", s['structure_name'] ?? "N/A"),
            _infoRow("Depth:", "${s['depth']} m"),
            _infoRow("Diameter:", "${s['diameter']} m"),
            _infoRow("Pipe Type:", widget.pipeType.toString()),
            _infoRow("Pipe Size:", widget.pipeSize.toString()),
            _infoRow(
              "Estimated Cost:",
              "₹${widget.arTotalCost?.toStringAsFixed(0)}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailedReportCard() {
    return FutureBuilder<String>(
      future: _detailedReportFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
                MarkdownBody(data: snapshot.data!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Edit Inputs"),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("Save Report"),
            onPressed: () async {
              final report = await _detailedReportFuture;
              await saveResultToFirebase(report);
              await generatePdf(report);
            },
          ),
        ),
      ],
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
