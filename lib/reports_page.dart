import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final CollectionReference reportsRef =
      FirebaseFirestore.instance.collection("results");

  Future<String> _detailedReportFuture = Future.value("");

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.description, size: 40, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your Assessment Reports',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'View, download and share your Rooftop Rain Water Harvesting reports',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Reports List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: reportsRef
                  .where('userId', isEqualTo: user?.uid).orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Reports Yet"));
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final data = report.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final formattedDate =
                        DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(data['structure'] ?? "Water Harvesting Report",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(formattedDate),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                              onPressed: () {
                                // show detailed report in preview
                                _detailedReportFuture = Future.value(data['detailedReport'] ?? "");
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: FutureBuilder<String>(
  future: _detailedReportFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text("Could not generate detailed report.");
    }
    return SingleChildScrollView(
      child: Card(
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
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  p: TextStyle(fontSize: 14),
                  tableBody: TextStyle(fontSize: 14),
                  tableHead: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
)

                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.green),
                              onPressed: () async {
                                final bytes = await generatePdf(data['detailedReport'] ?? "");
                                await savePdfToDevice(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("PDF downloaded successfully")));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.orange),
                              onPressed: () async {
                                final bytes = await generatePdf(data['detailedReport'] ?? "");
                                await sharePdf(bytes);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- PDF Functions -------------------

  Future<Uint8List> generatePdf(String detailedReport) async {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.nunitoRegular();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Water Harvesting Report", style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text(detailedReport, style: pw.TextStyle(font: ttf, fontSize: 12)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> savePdfToDevice(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Water_Harvesting_Report.pdf');
    await file.writeAsBytes(bytes);
  }

  Future<void> sharePdf(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Water_Harvesting_Report.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: "Water Harvesting Report");
  }

  // ------------------- Markdown Helper -------------------
  String cleanMarkdownForUI(String line) {
    line = line.replaceAll(RegExp(r'^#+\s*'), '');
    line = line.replaceAll(RegExp(r'\*\*'), '');
    line = line.replaceAll(RegExp(r'\*'), '');
    return line.trim();
  }
}
