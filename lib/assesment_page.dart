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
  bool _isRoofMaterialExpanded = false; // ✅ added missing variable
  String? _soilType; // holds selected soil type
  bool _isSoilTypeExpanded = false; // expansion state

  final List<Map<String, String>> _roofTypeOptions = [
    {'value': 'concrete', 'label': 'Concrete'},
    {'value': 'gi_sheet', 'label': 'GI Sheet'},
    {'value': 'asbestos', 'label': 'Asbestos'},
  ];

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

  // String _soilType = "Sandy";
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
    String aquiferType = aquiferData?["aquifer"] ?? "Unconfined Aquifer";

    Map<String, double> coefficients = {
      "concrete": 0.85,
      "gi_sheet": 0.95,
      "asbestos": 0.80,
    };
    double coeff = coefficients[_roofType] ?? 0.85;

    double annualDemand = dwellers * 135 * 365;
    double potentialLiters =
        (annualRainfall / 1000) * roofAreaM2 * coeff * 1000;

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

  Widget _buildTextExpandableSelector({
    required String title,
    required IconData icon,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).primaryColor, // ✅ same as TextFormField
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      selectedValue ?? title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: options.map((option) {
                        final isSelected = selectedValue == option['value'];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor ??
                                Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).primaryColor,
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            title: Text(
                              option['label'] ?? option['value']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              onChanged(option['value']);
                              onToggle(); // auto-collapse
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Please select your preferred assessment",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Assessment Selection Buttons
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 770,
                ), // same as form width
                child: Row(
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
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          foregroundColor: selectedAssessment == "Rooftop"
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Rooftop\nRainwater Harvesting",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          foregroundColor: selectedAssessment == "AR"
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Artificial\nRecharge (AR)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If no selection yet
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
              _buildForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ), // ✅ limit width for web
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  selectedAssessment == "Rooftop"
                      ? "Rainwater Harvesting Assessment"
                      : "Artificial Recharge Assessment",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
                      color: Theme.of(context).primaryColor,
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
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    label: const Text(
                      "Get My Location",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _getCurrentLocation,
                  ),
                ),
                const SizedBox(height: 16),

                // Inputs in grid if wide
                if (selectedAssessment == "Rooftop")
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  customTextField(
                                    controller: _roofAreaController,
                                    hint: "Rooftop Area (sqft)",
                                    icon: Icons.roofing,
                                  ),
                                  const SizedBox(height: 12),
                                  customTextField(
                                    controller: _openSpaceController,
                                    hint: "Open Space Area (sqft)",
                                    icon: Icons.landscape,
                                  ),
                                  const SizedBox(height: 12),
                                  customTextField(
                                    controller: _dwellersController,
                                    hint: "Number of Dwellers",
                                    icon: Icons.people,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextExpandableSelector(
                                    title: 'Select Roof Material',
                                    icon: Icons.roofing,
                                    options: _roofTypeOptions,
                                    selectedValue: _roofType,
                                    isExpanded: _isRoofMaterialExpanded,
                                    onToggle: () => setState(
                                      () => _isRoofMaterialExpanded =
                                          !_isRoofMaterialExpanded,
                                    ),
                                    onChanged: (value) => setState(
                                      () => _roofType = value ?? "concrete",
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.upload,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Upload Roof Photo (optional)",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                  if (_roofImage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Image.file(
                                        _roofImage!,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
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
                            _buildTextExpandableSelector(
                              title: 'Select Roof Material',
                              icon: Icons.roofing,
                              options: _roofTypeOptions,
                              selectedValue: _roofType,
                              isExpanded: _isRoofMaterialExpanded,
                              onToggle: () => setState(
                                () => _isRoofMaterialExpanded =
                                    !_isRoofMaterialExpanded,
                              ),
                              onChanged: (value) => setState(
                                () => _roofType = value ?? "concrete",
                              ),
                            ),
                            customTextField(
                              controller: _dwellersController,
                              hint: "Number of Dwellers",
                              icon: Icons.people,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.upload,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Upload Roof Photo (optional)",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _pickImage,
                            ),
                            if (_roofImage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Image.file(
                                  _roofImage!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        )
                else
                  Column(
                    children: [
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
                      _buildTextExpandableSelector(
                        title: 'Select Soil Type',
                        icon: Icons.landscape,
                        options: [
                          {'value': 'Sandy', 'label': 'Sandy'},
                          {'value': 'Clayey', 'label': 'Clayey'},
                          {'value': 'Loamy', 'label': 'Loamy'},
                        ],
                        selectedValue: _soilType,
                        isExpanded: _isSoilTypeExpanded,
                        onToggle: () => setState(
                          () => _isSoilTypeExpanded = !_isSoilTypeExpanded,
                        ),
                        onChanged: (value) =>
                            setState(() => _soilType = value ?? "Sandy"),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                _isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
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
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}
