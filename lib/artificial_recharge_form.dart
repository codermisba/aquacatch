import 'package:aquacatch/assessment_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:aquacatch/components.dart';
import 'package:aquacatch/ARResultPage.dart';
class ArtificialRechargeForm extends StatefulWidget {
  const ArtificialRechargeForm({super.key});

  @override
  _ArtificialRechargeFormState createState() => _ArtificialRechargeFormState();
}

class _ArtificialRechargeFormState extends State<ArtificialRechargeForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedRoofShape;
  String? _soilType;
  bool _isRoofMaterialExpanded = false;
  bool _isRoofShapeExpanded = false;

  final TextEditingController _noOfFloors = TextEditingController();
  final TextEditingController _openSpaceController =
      TextEditingController(); // sqm
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roofAreaController =
      TextEditingController(); // sqm

  final List<Map<String, String>> _roofTypeOptions = [
    {'value': 'concrete', 'label': 'Concrete'},
    {'value': 'gi_sheet', 'label': 'GI Sheet'},
    {'value': 'asbestos', 'label': 'Asbestos'},
  ];

  final List<Map<String, String>> _rooftopOptions = [
    {
      'value': 'Flat Roof',
      'label': 'Flat Roof',
      'image': 'assets/images/flat_roof.png',
    },
    {
      'value': 'Sloped Roof',
      'label': 'Sloped Roof',
      'image': 'assets/images/sloped_roof.png',
    },
  ];

  String _city = "Solapur"; // default
  String? _roofType;

  bool _isLoading = false;

  Map<String, double> runoffCoeff = {
    "gi_sheet": 0.90,
    "asbestos": 0.80,
    "tiledroof": 0.75,
    "concrete": 0.75,
  };

double calculateRRWHPotential({
  required double annualRainfall,
  required double roofArea,
  required double runoffCoefficient,
}) {
  // RRWH Potential (liters/year)
  // Formula: Rainfall (mm) * area (sqm) * runoff coefficient
  return annualRainfall * roofArea * runoffCoefficient;
}


double calculateARPotential({
  required double annualRainfall,
  required double roofArea,
  required double porosity,
  required double runoffCoefficient,
}) {
  // AR potential = rainfall * area * porosity * runoffCoeff
  return annualRainfall * roofArea * porosity * runoffCoefficient;
}

  /// ---------------- Location functions ----------------
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

   /// ------------------- API & Utility Functions -------------------

  Future<Map<String, dynamic>> _fetchRainfallData(String location) async {
    try {
      final geoUrl = Uri.parse(
        "https://nominatim.openstreetmap.org/search?city=$location&country=India&format=json&limit=1",
      );
      final geoResp = await http.get(
        geoUrl,
        headers: {"User-Agent": "RainHarvestApp/1.0"},
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

      double annualRainfall =
          dailyRainfall.fold(0.0, (prev, e) => prev + e);

      return {'annual': annualRainfall};
    } catch (e) {
      debugPrint("Rainfall error: $e");
      return {'annual': 1000.0};
    }
  }

  Future<Map<String, dynamic>?> _fetchDistrictData(String district) async {
    try {
      final url = Uri.parse(
        "https://sheetdb.io/api/v1/x7eb8wzkxon0e?district_lower=${Uri.encodeComponent(district.toLowerCase())}",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final row = data[0] as Map<String, dynamic>;
          return {
            "groundwaterlevel":
                double.tryParse(row["groundwaterlevel"].toString()) ?? 15.0,
            "soiltype": row["soiltype"] ?? "unknown",
            "porosity": double.tryParse(row["porosity"].toString()) ?? 0.40,
            "evaporation":
                double.tryParse(row["evaporation"].toString()) ?? 1200.0,
          };
        }
      }
    } catch (e) {
      debugPrint("District data fetch error: $e");
    }
    // fallback defaults
    return {
      "groundwaterlevel": 15.0,
      "soiltype": "unknown",
      "porosity": 0.40,
      "evaporation": 1200.0,
    };
  }

  Future<List<Map<String, dynamic>>> fetchARDataFromAPI() async {
  try {
    final url = Uri.parse("https://sheetdb.io/api/v1/domso538f6dw7");
    final response = await http.get(url);

    if (response.statusCode != 200) {
      debugPrint("AR API ERROR: ${response.statusCode}");
      return [];
    }
    
    final List decoded = json.decode(response.body);
    debugPrint("AR API SAMPLE ROW: ${decoded.first.keys}");
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (e) {
    debugPrint("AR API EXCEPTION: $e");
    return [];
  }
  }

 bool matchesRange(String rangeRaw, double roofArea) {
  if (rangeRaw.toString().trim().isEmpty) return false;

  final range = rangeRaw.trim();

  if (range.contains("<=")) {
    final limit = double.tryParse(range.replaceAll("<=", "").trim());
    return limit != null && roofArea <= limit;
  }

  if (range.contains("-")) {
    final parts = range.split("-");
    if (parts.length == 2) {
      final start = double.tryParse(parts[0].trim());
      final end = double.tryParse(parts[1].trim());
      return start != null && end != null && roofArea >= start && roofArea <= end;
    }
  }

  return false;
}

 Map<String, dynamic>? _getBestARStructure(
    double roofArea, List<dynamic> arData) {
  final matching = arData.where((item) {
    final range = (item["arroofarea(sqm)"] ?? item["arroofarea"] ?? "").toString();
    return matchesRange(range, roofArea);
  }).toList();

  if (matching.isEmpty) return null;

  // FIX: parse cost safely
  matching.sort((a, b) {
    double costA = double.tryParse(a["artotalcost"].toString()) ?? double.infinity;
    double costB = double.tryParse(b["artotalcost"].toString()) ?? double.infinity;
    return costA.compareTo(costB);
  });

  return matching.first as Map<String, dynamic>;
}


 

Map<String, dynamic>? getBestARStructure(
    double roofArea, List<Map<String, dynamic>> data) {
  if (data.isEmpty) return null;

  List<Map<String, dynamic>> matching = data.where((row) {
    return matchesRange(row["arroofarea(sqm)"], roofArea);
  }).toList();

  if (matching.isEmpty) return null;

  matching.sort((a, b) {
    double costA = double.tryParse(a["artotalcost"].toString()) ?? double.infinity;
    double costB = double.tryParse(b["artotalcost"].toString()) ?? double.infinity;
    return costA.compareTo(costB);
  });

  return matching.first;
}


  /// ---------------- Main calculation & navigation ----------------

  Future<void> _navigateToResult() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final String district = _locationController.text.trim();
  final double roofAreaSqm = double.tryParse(_roofAreaController.text) ?? 0.0;
  final String roofMat = _roofType ?? "concrete";

  // 1. Fetch API data
  final rainfall = await _fetchRainfallData(district);
  final districtData = await _fetchDistrictData(district);
  final arCostList = await fetchARDataFromAPI();

  // 2. Extract district-based values
  double porosity         = districtData?["porosity"] ?? 0.40;
  String soilType         = districtData?["soiltype"] ?? "unknown";
  double groundwaterLevel = districtData?["groundwaterlevel"] ?? 15.0;
  double evaporation      = districtData?["evaporation"] ?? 1200.0;

  double annualRainfall = rainfall['annual'];

  // Roof runoff coefficient
  double runoff = runoffCoeff[roofMat.toLowerCase()] ?? 0.75;

  // 3. Calculate RRWH Potential
  double rrwhPotential = calculateRRWHPotential(
    annualRainfall: annualRainfall,
    roofArea: roofAreaSqm,
    runoffCoefficient: runoff,
  );

  // 4. Calculate AR Potential
  double arPotential = calculateARPotential(
    annualRainfall: annualRainfall,
    roofArea: roofAreaSqm,
    porosity: porosity,
    runoffCoefficient: runoff,
  );

  // 5. Select best AR structure (dynamic map)
  final Map<String, dynamic>? bestStructure =
      _getBestARStructure(roofAreaSqm, arCostList);

  setState(() => _isLoading = false);

  // Convert values safely
double? parsedTotalCost = bestStructure?["artotalcost"] != null
    ? double.tryParse(bestStructure!["artotalcost"].toString())
    : null;

double? parsedMaxCost = bestStructure?["armaxcost"] != null
    ? double.tryParse(bestStructure!["armaxcost"].toString())
    : null;

String? pipeType = bestStructure?["arpipetype"]?.toString();
String? pipeSize = bestStructure?["arpipesize(mm)"]?.toString();
debugPrint("🏗️ BEST STRUCTURE (RAW MAP): $bestStructure");
debugPrint("💰 PARSED TOTAL COST: $parsedTotalCost");
  debugPrint("💰 PARSED MAX COST: $parsedMaxCost");
  debugPrint("🚰 PIPE TYPE: $pipeType");
  debugPrint("📏 PIPE SIZE: $pipeSize");

  // 6. Navigate with full dataset
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ARResultPage(
      district: district,
      roofArea: roofAreaSqm,
      roofMaterial: roofMat,
      rrwhPotential: rrwhPotential,
      arPotential: arPotential,
      soilType: soilType,
      porosity: porosity,
      evaporation: evaporation,
      groundwaterLevel: groundwaterLevel,
      annualRainfall: annualRainfall,

      arStructure: bestStructure,
      arTotalCost: parsedTotalCost,
      arMaxCost: parsedMaxCost,
      pipeType: pipeType,
      pipeSize: pipeSize,

      fullDistrictData: districtData,
    ),
  ),
);
  
}

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Artificial Recharge Assessment",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 80,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Artificial Recharge Assessment",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Location Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const Divider(),
                      customTextField(
                        context: context,
                        controller: _locationController,
                        hint: "Location",
                        icon: Icons.location_city,
                        validator: validateCity,
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
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      customTextField(
                                        context: context,
                                        controller: _roofAreaController,
                                        hint: "Rooftop Area (sqm)",
                                        icon: Icons.roofing,
                                        validator:(value) => validateNumber(value, 'Roof Area'),
                                      ),
                                      customTextField(
                                        context: context,
                                        controller: _openSpaceController,
                                        hint: "Open Space Area (sqm)",
                                        validator:(value) => validateNumber(value, 'Open Space'),
                                        icon: Icons.landscape,
                                      ),
                                      const SizedBox(height: 12),
                                      customTextField(
                                        context: context,
                                        controller: _noOfFloors,
                                        hint: "Enter no of floors",
                                        validator:(value) => validateNumber(value, 'No. of floors'),
                                        icon: Icons.business,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      buildExpandableSelector(
                                        context: context,
                                        title: 'Select Roof Shape',
                                        icon: Icons.home,
                                        options: _rooftopOptions,
                                        selectedValue: _selectedRoofShape,
                                        isExpanded: _isRoofShapeExpanded,
                                        validator: (value) => validateDropdown(value, 'Roof shape'),
                                        onToggle: () => setState(
                                          () => _isRoofShapeExpanded =
                                              !_isRoofShapeExpanded,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _selectedRoofShape =
                                              value ?? "Flat Roof",
                                        ),
                                      ),
                                      buildTextExpandableSelector(
                                        context: context,
                                        title: 'Select Roof Material',
                                        icon: Icons.roofing,
                                        options: _roofTypeOptions,
                                        selectedValue: _roofType,
                                        isExpanded: _isRoofMaterialExpanded,
                                        validator: (value) => validateDropdown(value, 'Roof Shape'),
                                        onToggle: () => setState(
                                          () => _isRoofMaterialExpanded =
                                              !_isRoofMaterialExpanded,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _roofType = value ?? "concrete",
                                        ),
                                      ),
                                     
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                buildExpandableSelector(
                                  context: context,
                                  title: 'Select Roof Shape',
                                  icon: Icons.home,
                                  options: _rooftopOptions,
                                  selectedValue: _selectedRoofShape,
                                  isExpanded: _isRoofShapeExpanded,
                                  validator: (value) => validateDropdown(value, 'Roof Type'),
                                  onToggle: () => setState(
                                    () => _isRoofShapeExpanded =
                                        !_isRoofShapeExpanded,
                                  ),
                                  onChanged: (value) => setState(
                                    () =>
                                        _selectedRoofShape = value ?? "Flat Roof",
                                  ),
                                ),
                                buildTextExpandableSelector(
                                  context: context,
                                  title: 'Select Roof Material',
                                  icon: Icons.roofing,
                                  options: _roofTypeOptions,
                                  selectedValue: _roofType,
                                  isExpanded: _isRoofMaterialExpanded,
                                  validator: (value) => validateDropdown(value, 'Roof Type'),
                                  onToggle: () => setState(
                                    () => _isRoofMaterialExpanded =
                                        !_isRoofMaterialExpanded,
                                  ),
                                  onChanged: (value) => setState(
                                    () => _roofType = value ?? "concrete",
                                  ),
                                ),
                                customTextField(
                                  context: context,
                                  controller: _openSpaceController,
                                  hint: "Open Space Area (sqft)",
                                  icon: Icons.landscape,
                                ),
                                customTextField(
                                  context: context,
                                  controller: _noOfFloors,
                                  hint: "Enter no of floors",
                                  icon: Icons.business,
                                ),
                                
                              ],
                            ),
                      const SizedBox(height: 28),
                      _isLoading
                          ? CircularProgressIndicator(color: primaryColor)
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
                                onPressed:() {
                  if (_formKey.currentState!.validate()) {
                    _navigateToResult();
                  }
                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
