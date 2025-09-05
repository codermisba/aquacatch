import 'package:flutter/material.dart';
import 'components.dart';
import 'result_page.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final TextEditingController _locationController =
      TextEditingController(text: "Solapur");
  final TextEditingController _pincodeController =
      TextEditingController(text: "413001");
  final TextEditingController _roofAreaController =
      TextEditingController(text: "120");
  final TextEditingController _openSpaceController =
      TextEditingController(text: "80");
  final TextEditingController _dwellersController =
      TextEditingController(text: "5");

  String _roofType = "concrete";
  bool _isLoading = false;

  void _navigateToResult() {
    setState(() => _isLoading = true);

    double rainfall = 781.5; // fallback rainfall mm
    Map<String, double> coefficients = {
      "concrete": 0.85,
      "gi_sheet": 0.95,
      "asbestos": 0.80,
    };

    double roofArea = double.tryParse(_roofAreaController.text) ?? 0;
    double openSpace = double.tryParse(_openSpaceController.text) ?? 0;
    //int dwellers = int.tryParse(_dwellersController.text) ?? 1;

    double coeff = coefficients[_roofType] ?? 0.85;
    double potentialM3 = (rainfall / 1000) * roofArea * coeff;
    double potentialLiters = potentialM3 * 1000;

    String structure;
    if (potentialLiters < 5000) {
      structure = "No need for harvesting";
    } else if (openSpace < 10) {
      structure = "Small tank on rooftop";
    } else if (potentialLiters > 20000) {
      structure = "Large underground tank";
    } else {
      structure = "Medium-sized surface tank";
    }

    Map<String, double> costs = {
      "Small tank on rooftop": 10000,
      "Medium-sized surface tank": 25000,
      "Large underground tank": 50000,
      "No need for harvesting": 0,
    };

    double cost = costs[structure] ?? 0;
    double savings = potentialLiters * 0.005;

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          rainfall: rainfall,
          potentialLiters: potentialLiters,
          structure: structure,
          cost: cost,
          savings: savings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Assessment",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assessment_outlined, size: 100, color: primaryColor),
              const SizedBox(height: 20),

              // Location & Pincode
              customTextField(
                  controller: _locationController,
                  hint: "Location",
                  icon: Icons.location_city),
              customTextField(
                  controller: _pincodeController,
                  hint: "Pincode",
                  icon: Icons.pin_drop),

              // Other fields
              customTextField(
                  controller: _roofAreaController,
                  hint: "Rooftop Area (m²)",
                  icon: Icons.roofing),
              customTextField(
                  controller: _openSpaceController,
                  hint: "Open Space Area (m²)",
                  icon: Icons.landscape),
              customTextField(
                  controller: _dwellersController,
                  hint: "Number of Dwellers",
                  icon: Icons.people),
              const SizedBox(height: 12),

              // Roof Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _roofType,
                decoration: InputDecoration(
                  labelText: "Roof Type",
                  prefixIcon: const Icon(Icons.home, color: primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: accentColor, width: 2),
                  ),
                ),
                items: ["concrete", "gi_sheet", "asbestos"]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _roofType = val!),
              ),
              const SizedBox(height: 20),

              // Buttons
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.file_present, color: Colors.white),
                            label: const Text("Generate Report",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _navigateToResult,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bolt, color: Colors.white),
                            label: const Text("Artificial Recharge",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3c8baa),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _navigateToResult,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
