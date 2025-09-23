import 'dart:typed_data';
// import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final CollectionReference reportsRef = FirebaseFirestore.instance.collection(
    "results",
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Assessment Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: reportsRef
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Reports Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Complete an assessment to generate your first report!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Filter reports: old (no userId) + current user's
                final reports = snapshot.data!.docs.where((doc) {
                  // If userId exists, check if it matches current user
                  // If it doesn't exist (old reports), include it
                  final data = doc.data() as Map<String, dynamic>;
                  return !data.containsKey('userId') ||
                      data['userId'] == user?.uid;
                }).toList();

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final timestamp = report['timestamp'] != null
                        ? (report['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final formattedDate = DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          report['structure'] ?? "Water Harvesting Report",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formattedDate),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResultPage(
                                    annualRainfall:
                                        (report['annualRainfall'] as num)
                                            .toDouble(),
                                    potentialLiters:
                                        (report['potentialLiters'] as num)
                                            .toDouble(),
                                    structure: report['structure'],
                                    cost: (report['cost'] as num).toDouble(),
                                    savings: (report['savings'] as num)
                                        .toDouble(),
                                    dwellers: report['dwellers'],
                                    roofArea: (report['roofArea'] as num)
                                        .toDouble(),
                                    groundwaterLevel:
                                        (report['groundwaterLevel'] as num)
                                            .toDouble(),
                                    aquiferType: report['aquiferType'] ?? '',
                                  ),
                                ),
                              );
                            } else if (value == 'download') {
                              await _generatePdf(report);
                            } else if (value == 'share') {
                              // TODO: share_plus implementation
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'view', child: Text('View')),
                            PopupMenuItem(
                              value: 'download',
                              child: Text('Download'),
                            ),
                            PopupMenuItem(value: 'share', child: Text('Share')),
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

  Future<void> _generatePdf(QueryDocumentSnapshot report) async {
    final pdf = pw.Document();

    final detailedReport =
        report['detailedReport'] ?? "No detailed report available.";

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Water Harvesting Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Structure: ${report['structure']}'),
            pw.Text('Roof Area: ${report['roofArea']} m²'),
            pw.Text('Annual Rainfall: ${report['annualRainfall']} mm'),
            pw.Text(
              'Potential Harvested Water: ${report['potentialLiters']} L',
            ),
            pw.Text(
              'Annual Water Demand: ${(report['dwellers'] * 135 * 365).toString()} L',
            ),
            pw.Text('Estimated Cost: ₹${report['cost']}'),
            pw.Text('Expected Savings: ₹${report['savings']}'),
            pw.Text('Aquifer Type: ${report['aquiferType']}'),
            pw.Text('Location: ${report['location'] ?? 'Not specified'}'),
            pw.Text('Groundwater Level: ${report['groundwaterLevel']} m'),
            pw.SizedBox(height: 16),
            pw.Text(
              'Detailed AI Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(detailedReport, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    // Save PDF as bytes
    final Uint8List bytes = await pdf.save();

    // ✅ For web: triggers print/save dialog
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Water_Harvesting_Report.pdf',
    );
  }
}
