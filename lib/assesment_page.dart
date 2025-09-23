import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'components.dart';
import 'result_page.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  String? selectedAssessment; // null → no selection yet

  // Common Controllers
  final TextEditingController _locationController = TextEditingController(
    text: "Solapur",
  );
  final TextEditingController _roofAreaController = TextEditingController(
    text: "120",
  ); // sqft
  final TextEditingController _openSpaceController = TextEditingController(
    text: "80",
  ); // sqft
  final TextEditingController _dwellersController = TextEditingController(
    text: "5",
  );

  // AR-specific controllers
  final TextEditingController _wellDepthController = TextEditingController(
    text: "10",
  ); // meters
  final TextEditingController _wellDiameterController = TextEditingController(
    text: "1",
  ); // meters
  String _soilType = "Sandy";
  String _city = "Solapur"; // default

  String _roofType = "concrete";
  File? _roofImage;
  bool _isLoading = false;

  /// 📸 Upload roof image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _roofImage = File(pickedFile.path);
      });
    }
  }

  /// 📍 Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.locality ?? '',
          place.subAdministrativeArea ?? '',
          place.administrativeArea ?? '',
        ].where((e) => e.isNotEmpty).join(", ");

        setState(() {
          _city = place.locality ?? _city;
          _locationController.text = address.isNotEmpty
              ? address
              : "${position.latitude}, ${position.longitude}";
        });
      } else {
        setState(() {
          _locationController.text =
              "${position.latitude}, ${position.longitude}";
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<double> fetchGroundwaterLevel(String district) async {
    try {
      final url = Uri.parse(
        "https://sheetdb.io/api/v1/x7eb8wzkxon0e?district_lower=${district.toLowerCase()}",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return double.tryParse(data[0]["groundwaterlevel"].toString()) ??
              15.0;
        }
      }
    } catch (e) {
      debugPrint("Groundwater fetch error: $e");
    }
    return 15.0; // fallback
  }

  /// 🚀 Generate Report
  Future<void> _navigateToResult() async {
    setState(() => _isLoading = true);

    String location = _locationController.text.trim();
    int dwellers = int.tryParse(_dwellersController.text) ?? 1;

    double roofAreaSqft = double.tryParse(_roofAreaController.text) ?? 0;
    double roofAreaM2 = roofAreaSqft * 0.092903;

    Map<String, dynamic> rainfallData = await _fetchRainfallData(location);
    double annualRainfall = rainfallData['annual'];

    double groundwaterLevel = await fetchGroundwaterLevel(location);
    final aquiferData = await fetchAquiferData(location);
    String aquiferType = "Unconfined Aquifer"; // default
    if (aquiferData != null && aquiferData["aquifer"] != null) {
      aquiferType = aquiferData["aquifer"];
    }

    Map<String, double> coefficients = {
      "concrete": 0.85,
      "gi_sheet": 0.95,
      "asbestos": 0.80,
    };
    double coeff = _roofType != null ? coefficients[_roofType] ?? 0.85 : 0.85;

    double annualDemand = dwellers * 135 * 365;
    double potentialLiters = (annualRainfall / 1000) * roofAreaM2 * coeff * 1000;

    String structure;
    if (selectedAssessment == "AR") {
      double wellDepth = double.tryParse(_wellDepthController.text) ?? 10;
      double wellDiameter = double.tryParse(_wellDiameterController.text) ?? 1;
      structure = "AR Well: $wellDepth m depth, $wellDiameter m diameter";
    } else {
      if (potentialLiters < 0.5 * annualDemand) {
        structure = "Small tank on rooftop";
      } else if (potentialLiters > 4 * annualDemand) {
        structure = "Large underground tank";
      } else {
        structure = "Medium-sized surface tank";
      }
    }

    Map<String, double> costs = {
      "Small tank on rooftop": 10000,
      "Medium-sized surface tank": 25000,
      "Large underground tank": 50000,
      "Recharge Shaft": 20000,
      "Recharge Pit": 30000,
      "Percolation Pond": 60000,
    };
    double cost = costs[structure] ?? 0;
    double savings = potentialLiters * 0.005;

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          annualRainfall: annualRainfall,
          potentialLiters: potentialLiters,
          structure: structure,
          cost: cost,
          savings: savings,
          dwellers: dwellers,
          roofArea: roofAreaSqft,
          groundwaterLevel: groundwaterLevel,
          aquiferType: aquiferType,
          city: location,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchRainfallData(String location) async {
    try {
      final geoUrl = Uri.parse(
        "https://nominatim.openstreetmap.org/search?city=$location&country=India&format=json&limit=1",
      );

      final geoResp = await http.get(
        geoUrl,
        headers: {"User-Agent": "RainHarvestApp/1.0 (contact@email.com)"},
      );

      if (geoResp.statusCode != 200) return {'annual': 1000.0};

      final geoData = json.decode(geoResp.body);
      if (geoData.isEmpty) return {'annual': 1000.0};

      double lat = double.parse(geoData[0]["lat"]);
      double lon = double.parse(geoData[0]["lon"]);

      DateTime today = DateTime.now();
      DateTime lastYear = today.subtract(const Duration(days: 365));

      String start =
          "${lastYear.year}${lastYear.month.toString().padLeft(2, '0')}${lastYear.day.toString().padLeft(2, '0')}";
      String end =
          "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

      final nasaUrl = Uri.parse(
        "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=PRECTOTCORR&community=AG&longitude=$lon&latitude=$lat&start=$start&end=$end&format=JSON",
      );

      final nasaResp = await http.get(nasaUrl);
      if (nasaResp.statusCode != 200) return {'annual': 1000.0};

      final nasaData = json.decode(nasaResp.body);
      Map<String, dynamic> values =
          nasaData["properties"]["parameter"]["PRECTOTCORR"];

      List<double> dailyRainfall = values.values
          .map((e) => e == null ? 0.0 : (e as num).toDouble())
          .map((e) => e < 0 ? 0.0 : e)
          .toList();

      double annualRainfall = dailyRainfall.fold(0.0, (prev, e) => prev + e);

      return {'annual': annualRainfall};
    } catch (e) {
      debugPrint("Rainfall error: $e");
      return {'annual': 1000.0};
    }
  }

  Future<Map<String, dynamic>?> fetchAquiferData(String district) async {
    final url = Uri.parse(
      "https://sheetdb.io/api/v1/pf4x54gmu8jmt/search?district_lower=$district",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        return {
          "state": data[0]["State"],
          "district": data[0]["District"],
          "aquifer": data[0]["Aquifer"],
        };
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                "Please select your preferred assessment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Assessment Selection Buttons (always visible)
            Row(
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
              ? primaryColor
              : Colors.grey.shade200,
          foregroundColor: selectedAssessment == "Rooftop"
              ? Colors.white
              : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Rooftop\nRainwater Harvesting",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              ? accentColor
              : Colors.grey.shade200,
          foregroundColor: selectedAssessment == "AR"
              ? Colors.white
              : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Artificial\nRecharge (AR)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ],
),

            const SizedBox(height: 20),

            // If no selection yet, prompt; otherwise show the form
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
              Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.assessment_outlined,
                          size: 80,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedAssessment == "Rooftop"
                              ? "Rainwater Harvesting Assessment"
                              : "Artificial Recharge Assessment",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Location Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Location Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const Divider(),
                        customTextField(
                          controller: _locationController,
                          hint: "Location",
                          icon: Icons.location_city,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Get My Location",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _getCurrentLocation,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Form fields
                        if (selectedAssessment == "Rooftop") ...[
                          // Rooftop Fields
                          customTextField(
                            controller: _roofAreaController,
                            hint: "Rooftop Area (sqft)",
                            icon: Icons.roofing,
                          ),
                          customTextField(
                            controller: _openSpaceController,
                            hint: "Open Space Area (sqft)",
                            icon: Icons.landscape,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _roofType,
                            items: ["concrete", "gi_sheet", "asbestos"].map((
                              type,
                            ) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type[0].toUpperCase() + type.substring(1),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _roofType = val ?? "concrete";
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Roof Type",
                              prefixIcon: const Icon(Icons.roofing),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          customTextField(
                            controller: _dwellersController,
                            hint: "Number of Dwellers",
                            icon: Icons.people,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.upload,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Upload Roof Photo (optional)",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                          if (_roofImage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Image.file(
                                _roofImage!,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ] else ...[
                          // AR Fields
                          customTextField(
                            controller: _wellDepthController,
                            hint: "Well Depth (m)",
                            icon: Icons.height,
                          ),
                          customTextField(
                            controller: _wellDiameterController,
                            hint: "Well Diameter (m)",
                            icon: Icons.circle,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _soilType,
                            items: ["Sandy", "Clayey", "Loamy"].map((soil) {
                              return DropdownMenuItem(
                                value: soil,
                                child: Text(soil),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _soilType = val ?? "Sandy";
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Soil Type",
                              prefixIcon: const Icon(Icons.landscape),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _isLoading
                            ? const CircularProgressIndicator(
                                color: primaryColor,
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.file_present,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Generate Report",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _navigateToResult,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
