import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'components.dart';
import 'result_page.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final TextEditingController _locationController =
      TextEditingController(text: "Solapur");
  final TextEditingController _pincodeController =
      TextEditingController(text: "413001");
  final TextEditingController _roofAreaController =
      TextEditingController(text: "120"); // sqft
  final TextEditingController _openSpaceController =
      TextEditingController(text: "80"); // sqft
  final TextEditingController _dwellersController =
      TextEditingController(text: "5");

  String _roofType = "concrete";
  bool _isLoading = false;

  /// 🚀 Navigate to result page after calculations
Future<void> _navigateToResult() async {
  setState(() => _isLoading = true);

  String location = _locationController.text.trim();
  String pincode = _pincodeController.text.trim();
  int dwellers = int.tryParse(_dwellersController.text) ?? 1;

  // ✅ Convert sqft to m² for calculation
  double roofAreaSqft = double.tryParse(_roofAreaController.text) ?? 0;
  // double openSpaceSqft = double.tryParse(_openSpaceController.text) ?? 0;
  double roofAreaM2 = roofAreaSqft * 0.092903; // 1 sqft = 0.092903 m²
  // double openSpaceM2 = openSpaceSqft * 0.092903;

  // Fetch rainfall (mm)
  Map<String, dynamic> rainfallData = await _fetchRainfallData(location, pincode);
  double annualRainfall = rainfallData['annual']; // mm/year
  // List<double> last7Days = rainfallData['last7Days'];

  // Runoff coefficient
  Map<String, double> coefficients = {
    "concrete": 0.85,
    "gi_sheet": 0.95,
    "asbestos": 0.80,
  };
  double coeff = coefficients[_roofType] ?? 0.85;

  // Annual water demand (liters)
  double annualDemand = dwellers * 135 * 365; // 135 liters per person per day

  // Potential harvested water (liters)
  // annualRainfall (mm) * roofArea (m²) * coeff * 1000 = liters
  double potentialLiters = (annualRainfall / 1000) * roofAreaM2 * coeff * 1000;

  // Structure recommendation based on potential vs demand
  String structure;
  if (potentialLiters < 0.5 * annualDemand) {
    structure = "Small tank on rooftop";
  } else if (potentialLiters > 4 * annualDemand) {
    structure = "Large underground tank";
  } else {
    structure = "Medium-sized surface tank";
  }

  // Cost estimation
  Map<String, double> costs = {
    "Small tank on rooftop": 10000,
    "Medium-sized surface tank": 25000,
    "Large underground tank": 50000,
  };
  double cost = costs[structure] ?? 0;

  // Savings calculation (assume ₹ per liter)
  double savings = potentialLiters * 0.005; // adjust rate if needed

  setState(() => _isLoading = false);

  // Navigate to result page
  Navigator.push(
    // ignore: use_build_context_synchronously
    context,
    MaterialPageRoute(
      builder: (_) => ResultPage(
        annualRainfall: annualRainfall,
        potentialLiters: potentialLiters,
        structure: structure,
        cost: cost,
        savings: savings,
        dwellers: dwellers,
        roofArea: roofAreaSqft, // show sqft to user
        // openSpace: openSpaceSqft, // show sqft to user
        // annualDemand: annualDemand,
        // last7Days: last7Days,
      ),
    ),
  );
}

  /// 🌧 Fetch rainfall using location + pincode
Future<Map<String, dynamic>> _fetchRainfallData(String location, String pincode) async {
  try {
    // 1️⃣ Get coordinates (lat, lon) from OpenStreetMap
    final geoUrl = Uri.parse(
        "https://nominatim.openstreetmap.org/search?city=$location&postalcode=$pincode&country=India&format=json&limit=1");
    final geoResp = await http.get(
      geoUrl,
      headers: {"User-Agent": "RainHarvestApp/1.0 (your_email@example.com)"},
    );

    if (geoResp.statusCode != 200) {
      return {'annual': 1000.0, 'last7Days': List.filled(7, 2.0)};
    }

    final geoData = json.decode(geoResp.body);
    if (geoData.isEmpty) {
      return {'annual': 1000.0, 'last7Days': List.filled(7, 2.0)};
    }

    double lat = double.parse(geoData[0]["lat"]);
    double lon = double.parse(geoData[0]["lon"]);

    // 2️⃣ Dates for NASA POWER API
    DateTime today = DateTime.now();
    DateTime lastYear = today.subtract(const Duration(days: 365));

    String startDate = "${lastYear.year}${lastYear.month.toString().padLeft(2,'0')}${lastYear.day.toString().padLeft(2,'0')}";
    String endDate = "${today.year}${today.month.toString().padLeft(2,'0')}${today.day.toString().padLeft(2,'0')}";

    // 3️⃣ NASA POWER API request (daily corrected precipitation = PRECTOTCORR)
    final nasaUrl = Uri.parse(
        "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=PRECTOTCORR&community=AG&longitude=$lon&latitude=$lat&start=$startDate&end=$endDate&format=JSON");

    final nasaResp = await http.get(nasaUrl);

    if (nasaResp.statusCode != 200) {
      return {'annual': 1000.0, 'last7Days': List.filled(7, 2.0)};
    }

    final nasaData = json.decode(nasaResp.body);

    // 4️⃣ Extract daily precipitation (mm/day) and filter invalid values
    Map<String, dynamic> values = nasaData["properties"]["parameter"]["PRECTOTCORR"];
    List<double> dailyRainfall = values.values
    .map((e) => e == null ? 0.0 : (e as num).toDouble())
    .map((e) => e < 0 ? 0.0 : e)
    .toList()
    .cast<double>();

    // 5️⃣ Annual rainfall
    double annualRainfall = dailyRainfall.fold(0.0, (prev, e) => prev + e);

    // 6️⃣ Last 7 days rainfall
    List<double> last7Days = dailyRainfall.length >= 7
        ? dailyRainfall.skip(dailyRainfall.length - 7).toList()
        : List.from(dailyRainfall);

    return {'annual': annualRainfall, 'last7Days': last7Days};
  } catch (e) {
    debugPrint("Rainfall API Error: $e");
    return {'annual': 1000.0, 'last7Days': List.filled(7, 2.0)};
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Assessment", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assessment_outlined,
                      size: 80, color: primaryColor),
                  const SizedBox(height: 10),
                  const Text(
                    "Rainwater Harvesting Assessment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                  const SizedBox(height: 20),

                  /// Location details
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Location Details",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800])),
                  ),
                  const Divider(),
                  customTextField(
                      controller: _locationController,
                      hint: "Location",
                      icon: Icons.location_city),
                  customTextField(
                      controller: _pincodeController,
                      hint: "Pincode",
                      icon: Icons.pin_drop),

                  const SizedBox(height: 16),

                  /// House details
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("House Details",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800])),
                  ),
                  const Divider(),
                  customTextField(
                      controller: _roofAreaController,
                      hint: "Rooftop Area (sqft)",
                      icon: Icons.roofing),
                  customTextField(
                      controller: _openSpaceController,
                      hint: "Open Space Area (sqft)",
                      icon: Icons.landscape),
                  customTextField(
                      controller: _dwellersController,
                      hint: "Number of Dwellers",
                      icon: Icons.people),
                  const SizedBox(height: 12),

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
                    ),
                    items: ["concrete", "gi_sheet", "asbestos"]
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _roofType = val!),
                  ),

                  const SizedBox(height: 24),

                  /// Buttons
                  _isLoading
                      ? const CircularProgressIndicator(color: primaryColor)
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.file_present,
                                    color: Colors.white),
                                label: const Text("Generate Report",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor),
                                onPressed: _navigateToResult,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.water_drop,
                                    color: Colors.white),
                                label: const Text("Artificial Recharge",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor),
                                onPressed: _navigateToResult,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
