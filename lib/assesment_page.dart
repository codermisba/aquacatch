import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:aquacatch/components.dart';
import 'result_page.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  String? _selectedRoofShape;
  bool _isRoofShapeExpanded = false;

  bool _isFilterExpanded = false;
  String? _selectedFilterType;
  String? selectedAssessment; // null → no selection yet
  bool _isRoofMaterialExpanded = false;
  String? _soilType;
  bool _isSoilTypeExpanded = false;

  final List<Map<String, String>> _filterOptions = [
    {'value': 'sandfilter', 'label': 'Sand Filter', 'image': 'assets/images/sand_filter.jpg'},
    {'value': 'charcoalfilter', 'label': 'Charcoal Filter', 'image': 'assets/images/charcoal_filter.png'},
    {'value': 'rccfirstflushfilter', 'label': 'RCC First Flush Filter', 'image': 'assets/images/first_flush.png'}
  ];

  final List<Map<String, String>> _roofTypeOptions = [
    {'value': 'concrete', 'label': 'Concrete'},
    {'value': 'gi_sheet', 'label': 'GI Sheet'},
    {'value': 'asbestos', 'label': 'Asbestos'},
  ];

  final List<Map<String, String>> _locationTypeOptions = [
    {'value': 'urban', 'label': 'Urban'},
    {'value': 'suburban', 'label': 'Suburban'},
    {'value': 'rural', 'label': 'Rural'},
  ];

  final List<Map<String, String>> _rooftopOptions = [
    {'value': 'Flat Roof', 'label': 'Flat Roof', 'image': 'assets/images/flat_roof.png'},
    {'value': 'Sloped Roof', 'label': 'Sloped Roof', 'image': 'assets/images/sloped_roof.png'},
  ];

  String? _selectedLocationType;
  bool _isLocationTypeExpanded = false;

  // Common Controllers
  final TextEditingController _locationController = TextEditingController(text: "Solapur");
  final TextEditingController _roofAreaController = TextEditingController(text: "120"); // sqft by default in UI
  final TextEditingController _openSpaceController = TextEditingController(text: "80"); // sqft
  final TextEditingController _noOfFloors = TextEditingController(text: "1");
  final TextEditingController _dwellersController = TextEditingController(text: "5");

  // AR-specific controllers
  final TextEditingController _wellDepthController = TextEditingController(text: "10"); // meters
  final TextEditingController _wellDiameterController = TextEditingController(text: "1"); // meters

  String _city = "Solapur"; // default
  String _roofType = "concrete";

  File? _roofImage;
  bool _isLoading = false;

  /// ---------------- Normalizers & helpers ----------------

  /// Normalize structure names to match JSON keys like 'smallsurface', 'mediumsurface', 'largesurface', etc.
  String normalizeStructure(String input) {
    if (input == null) return "";
    String s = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    // handle known patterns
    if (s.contains("smallsurface")) return "smallsurface";
    if (s.contains("smallmedium")) return "smallmediumsurface";
    if (s.contains("mediumlarge")) return "mediumlargesurface";
    if (s.contains("mediumsurface")) return "mediumsurface";
    if (s.contains("largesurface")) return "largesurface";
    if (s.contains("verylarge")) return "verylargesurface";
    if (s.contains("extensive")) return "extensivesurface";
    if (s.contains("ar")) return "arsurface";
    // fallback: remove spaces
    return s;
  }

  /// Normalize filter type to match JSON keys: 'sandfilter','charcoalfilter','rccfirstflushfilter'
  String normalizeFilter(String? input) {
    if (input == null) return "";
    String s = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (s.contains("sand")) return "sandfilter";
    if (s.contains("charcoal")) return "charcoalfilter";
    if (s.contains("firstflush") || s.contains("rcc")) return "rccfirstflushfilter";
    if (s.contains("mesh")) return "meshorscreenfilter";
    return s;
  }

  /// Get roof area range string the dataset uses (ranges are in square metres).
  String getRoofAreaRangeFromSqm(double roofAreaSqm) {
  if (roofAreaSqm <= 100) {
    return "<=100";
  } else if (roofAreaSqm <= 250) {
    return "101-250";
  } else if (roofAreaSqm <= 500) {
    return "251-500";
  } else if (roofAreaSqm <= 1000) {
    return "501-1000";
  } else if (roofAreaSqm <= 2000) {
    return "1001-2000";
  } else {
    return ">2000"; // fallback for very large roofs
  }
}


  /// ---------------- Image picker ----------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _roofImage = File(pickedFile.path));
    }
  }

  /// ---------------- Location functions ----------------
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [place.locality ?? '', place.subAdministrativeArea ?? '', place.administrativeArea ?? '']
            .where((e) => e.isNotEmpty)
            .join(", ");
        setState(() {
          _city = place.locality ?? _city;
          _locationController.text = address.isNotEmpty ? address : "${position.latitude}, ${position.longitude}";
        });
      } else {
        setState(() {
          _locationController.text = "${position.latitude}, ${position.longitude}";
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<double> fetchGroundwaterLevel(String district) async {
    try {
      final url = Uri.parse("https://sheetdb.io/api/v1/x7eb8wzkxon0e?district_lower=${district.toLowerCase()}");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return double.tryParse(data[0]["groundwaterlevel"].toString()) ?? 15.0;
        }
      }
    } catch (e) {
      debugPrint("Groundwater fetch error: $e");
    }
    return 15.0; // fallback
  }

  /// ---------------- Load JSON cost data ----------------
  Future<List<dynamic>> loadRooftopCostData() async {
    final String response = await rootBundle.loadString('assets/rrwhcostdata.json');
    final Map<String, dynamic> data = json.decode(response);
    return data['Sheet1'] as List<dynamic>;
  }

  Future<List<dynamic>> loadARCostData() async {
    final String response = await rootBundle.loadString('assets/arcostdata.json');
    final Map<String, dynamic> data = json.decode(response);
    return data['Sheet1'] as List<dynamic>;
  }

  /// ---------------- Runoff Coefficients ----------------
  Map<String, double> runoffCoeff = {
    "gi_sheet": 0.90,
    "asbestos": 0.80,
    "tiledroof": 0.75,
    "concrete": 0.75,
  };

  /// ---------------- Costs helpers ----------------
  double getPipeUnitCostFallback(String pipeType) {
    final Map<String, double> pipeCostData = {"pvc": 120, "gi": 300, "hdpe": 150};
    return pipeCostData[pipeType.toLowerCase()] ?? 150;
  }

  double calculateWaterHarvested({required double annualRainfall, required double roofAreaSqm, required String roofType}) {
    final coeff = runoffCoeff[roofType.toLowerCase()] ?? 0.75;
    return (annualRainfall / 1000) * roofAreaSqm * coeff * 1000;
  }

  double calculatePipeLength({required int numberOfFloors, required String roofShape, double verticalPerFloor = 3.5, double horizontalLength = 10.0}) {
    double totalLength = numberOfFloors * verticalPerFloor;
    if (roofShape.toLowerCase().contains("sloped")) totalLength += horizontalLength;
    return totalLength;
  }

  double calculatePipeCost({required double totalLength, required double unitCostPerMeter}) {
    return totalLength * unitCostPerMeter;
  }

  double calculateTankCost({required double capacityLiters, required String brand}) {
    final costPerLitre = plasticTankCost[brand] ?? 1.0;
    return capacityLiters * costPerLitre;
  }

  /// ---------------- Plastic Tank Costs ----------------
  Map<String, double> plasticTankCost = {"Hindustan": 1.80, "Jindal": 1.80, "Storex": 0.75, "Ganga": 0.75};

  double calculateSavings(double harvestedLiters) {
    return harvestedLiters * 0.5; // ₹0.5 per liter
  }
/// ---------------- Pipe Unit Cost ----------------
double getPipeUnitCost(String pipeType) {
  Map<String, double> pipeCostData = {
    "pvc": 120,
    "gi": 300,
    "hdpe": 150,
  };
  return pipeCostData[pipeType.toLowerCase()] ?? 150;
}
  /// ---------------- Main calculation & navigation ----------------
Future<void> _navigateToResult() async {
  setState(() => _isLoading = true);

  // read user inputs
  String location = _locationController.text.trim();
  int dwellers = int.tryParse(_dwellersController.text) ?? 1;
  double roofAreaSqft = double.tryParse(_roofAreaController.text) ?? 0;
  double roofAreaSqm = roofAreaSqft * 0.092903; // convert to m²

  // rainfall and aquifer data
  Map<String, dynamic> rainfallData = await _fetchRainfallData(location);
  double annualRainfall = (rainfallData['annual'] ?? 1000.0) as double;

  double groundwaterLevel = await fetchGroundwaterLevel(location);
  final aquiferData = await fetchAquiferData(location);
  String aquiferType = aquiferData?["aquifer"] ?? "Unconfined Aquifer";

  // harvested water vs demand
  double potentialLiters = calculateWaterHarvested(
    annualRainfall: annualRainfall,
    roofAreaSqm: roofAreaSqm,
    roofType: _roofType,
  );
  double annualDemand = dwellers * 135 * 365;

  // structure selection
  String structureKey;
 if (selectedAssessment == "AR") {
    double porosity = 0.35; // assume porosity
    double runoffCoeffAR = runoffCoeff[_roofType.toLowerCase()] ?? 0.75;

    double rechargeLiters =
        porosity * annualRainfall * roofAreaSqm * runoffCoeffAR;

    // try AR JSON cost
    List<dynamic> data = await loadARCostData();
    Map<String, dynamic>? match;
    try {
      match = data.firstWhere((row) =>
          (row['Structure'] ?? '').toString().toLowerCase() == "pit");
    } catch (_) {
      match = null;
    }

    double totalCost = 16791.5; // fallback cost
    if (match != null) {
      totalCost = double.tryParse(match['totalcost'].toString()) ?? totalCost;
    }

    setState(() => _isLoading = false);

    // show result dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Artificial Recharge Result"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Recharge Potential: ${rechargeLiters.toStringAsFixed(0)} L"),
            const SizedBox(height: 10),
            Text("Estimated Cost: ₹${totalCost.toStringAsFixed(0)}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    return; // 🚨 exit early so Rooftop flow doesn’t run
  } if (roofAreaSqm <= 100) {
    structureKey = "smallsurface";
  } else if (roofAreaSqm <= 250) {
    structureKey = "smallmediumsurface";
  } else if (roofAreaSqm <= 500) {
    structureKey = "mediumsurface";
  } else if (roofAreaSqm <= 2000) {
    structureKey = "largesurface";
  } else {
    structureKey = "largesurface"; // fallback for >2000
  }

  
  structureKey = normalizeStructure(structureKey);

  // filter and pipe defaults
  String filterKey = normalizeFilter(_selectedFilterType ?? "sandfilter");
  String pipeType = "pvc";

  // pipe length & base cost
  int numberOfFloors = int.tryParse(_noOfFloors.text) ?? 1;
  String roofShape = _selectedRoofShape ?? "Flat Roof";
  double pipeLength = calculatePipeLength(
    numberOfFloors: numberOfFloors,
    roofShape: roofShape,
  );
  double unitPipeCost = getPipeUnitCost(pipeType);
  double pipeCost = calculatePipeCost(
    totalLength: pipeLength,
    unitCostPerMeter: unitPipeCost,
  );

  // tank cost (cheapest brand)
  String selectedTankBrand = plasticTankCost.entries
      .reduce((a, b) => a.value < b.value ? a : b)
      .key;
  double tankCost = calculateTankCost(
    capacityLiters: potentialLiters,
    brand: selectedTankBrand,
  );

  // initialize costs
  double installationCost = 0.0;
  double totalCost = 0.0;
  double filterCost = 0.0;

  String roofRange = getRoofAreaRangeFromSqm(roofAreaSqft);

  try {
    final data = (selectedAssessment == "AR")
        ? await loadARCostData()
        : await loadRooftopCostData();

    final match = data.firstWhere((row) {
      String rowStructure =
          normalizeStructure((row['Structure'] ?? row['structure'] ?? '').toString());
      String rowRoofRange =
          (row['roofarearange'] ?? row['roofAreaRange'] ?? '').toString();
      String rowPipeType =
          (row['pipetype'] ?? row['pipeType'] ?? '').toString().toLowerCase();
      String rowFilter =
          normalizeFilter((row['filter'] ?? row['filtertype'] ?? '').toString());

      return rowStructure == structureKey &&
          rowRoofRange == roofRange &&
          rowPipeType == pipeType.toLowerCase() &&
          rowFilter == filterKey;
    }, orElse: () => {});

    if (match != null && (match as Map).isNotEmpty) {
  final m = match as Map;

  installationCost = (m['installationcost'] != null)
      ? (m['installationcost'] as num).toDouble()
      : 0.0;

  filterCost = (m['filtercost'] != null)
      ? (m['filtercost'] as num).toDouble()
      : 0.0;

  double labourCost = (m['labourcost'] != null)
      ? (m['labourcost'] as num).toDouble()
      : 0.0;

  // ✅ Override pipe cost if JSON provides
  double jsonPipecostPerM = 0.0;
  if (m.containsKey('pipecost(m)')) {
    jsonPipecostPerM = (m['pipecost(m)'] as num).toDouble();
  } else if (m.containsKey('pipecost')) {
    jsonPipecostPerM = (m['pipecost'] as num).toDouble();
  }
  if (jsonPipecostPerM > 0) {
    unitPipeCost = jsonPipecostPerM;
    pipeCost = calculatePipeCost(
      totalLength: pipeLength,
      unitCostPerMeter: unitPipeCost,
    );
  }

  // ✅ total cost calculation
  if (m.containsKey('totalcost')) {
    totalCost = (m['totalcost'] as num).toDouble();
  } else {
    totalCost = installationCost + filterCost + pipeCost + tankCost;
  }
}

// ✅ Fallback when costs are missing or 0
if (installationCost == 0.0 || filterCost == 0.0 || totalCost == 0.0) {
  final defaults = getDefaultCosts(structureKey);

  if (installationCost == 0.0) {
    installationCost = defaults["installation"]!;
  }
  if (filterCost == 0.0) {
    filterCost = defaults["filter"]!;
  }
  if (totalCost == 0.0) {
    totalCost = installationCost + filterCost + pipeCost + tankCost;
  }
}
} catch (e) {
    debugPrint("Error during cost lookup: $e");
    // installationCost = 0.0;
    // filterCost = 0.0;
    // totalCost = tankCost + installationCost + pipeCost + filterCost;
  }

  double savings = calculateSavings(potentialLiters);

  setState(() => _isLoading = false);

  final selectedFilterLabel = _selectedFilterType ?? filterKey;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ResultPage(
        annualRainfall: annualRainfall,
        potentialLiters: potentialLiters,
        structure: structureKey,
        filterType: selectedFilterLabel,
        pipeType: pipeType,
        pipeLength: pipeLength,
        pipeCost: pipeCost,
        filterCost: filterCost,
        installationCost: installationCost,
        totalCost: totalCost,
        savings: savings,
        dwellers: dwellers,
        roofArea: roofAreaSqm,
        groundwaterLevel: groundwaterLevel,
        aquiferType: aquiferType,
        city: location,
      ),
    ),
  );
}

// ✅ Fallback function: gives defaults based on structure
Map<String, double> getDefaultCosts(String structureKey) {
  switch (structureKey) {
    case "smallsurface":
      return {
        "installation": 2000,
        "filter": 1000,
      };
    case "smallmediumsurface":
      return {
        "installation": 4000,
        "filter": 1500,
      };
    case "mediumsurface":
      return {
        "installation": 6000,
        "filter": 2000,
      };
    case "largesurface":
      return {
        "installation": 10000,
        "filter": 3000,
      };
    case "arsurface":
      return {
        "installation": 8000,
        "filter": 2500,
      };
    default:
      return {
        "installation": 5000,
        "filter": 2000,
      };
  }
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
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  context: context,
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
                buildTextExpandableSelector(
                  context: context,
                  title: 'Select Location Type',
                  icon: Icons.location_city,
                  options: _locationTypeOptions,
                  selectedValue: _selectedLocationType,
                  isExpanded: _isLocationTypeExpanded,
                  onToggle: () => setState(
                    () => _isLocationTypeExpanded = !_isLocationTypeExpanded,
                  ),
                  onChanged: (value) => setState(
                    () => _selectedLocationType =
                        value ?? "urban", // default value
                  ),
                ),
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
                                    context: context,
                                    controller: _roofAreaController,
                                    hint: "Rooftop Area (sqft)",
                                    icon: Icons.roofing,
                                  ),
                                  const SizedBox(height: 12),
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
                                  const SizedBox(height: 12),
                                  customTextField(
                                    context: context,
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
                                  buildExpandableSelector(
                                    context: context,
                                    title: 'Select Roof Shape',
                                    icon: Icons.home,
                                    options: _rooftopOptions,
                                    selectedValue: _selectedRoofShape,
                                    isExpanded: _isRoofShapeExpanded,
                                    onToggle: () => setState(
                                      () => _isRoofShapeExpanded =
                                          !_isRoofShapeExpanded,
                                    ),
                                    onChanged: (value) => setState(
                                      () => _selectedRoofShape =
                                          value ?? "Flat roof",
                                    ),
                                  ),

                                  buildTextExpandableSelector(
                                    context: context,
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

                                  buildExpandableSelector(
                                    context: context,
                                    title: 'Select Filter Type',
                                    icon: Icons.filter_alt,
                                    options: _filterOptions,
                                    selectedValue: _selectedFilterType,
                                    isExpanded: _isFilterExpanded,
                                    onToggle: () => setState(
                                      () => _isFilterExpanded =
                                          !_isFilterExpanded,
                                    ),
                                    onChanged: (value) => setState(
                                      () => _selectedFilterType = value,
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
                            buildExpandableSelector(
                              context: context,
                              title: 'Select Roof Shape',
                              icon: Icons.home,
                              options: _rooftopOptions,
                              selectedValue: _selectedRoofShape,
                              isExpanded: _isRoofShapeExpanded,
                              onToggle: () => setState(
                                () => _isRoofShapeExpanded =
                                    !_isRoofShapeExpanded,
                              ),
                              onChanged: (value) => setState(
                                () => _selectedRoofShape = value ?? "Flat roof",
                              ),
                            ),
                            customTextField(
                              context: context,
                              controller: _roofAreaController,
                              hint: "Rooftop Area (sqft)",
                              icon: Icons.roofing,
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

                            buildTextExpandableSelector(
                              context: context,
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
                            buildExpandableSelector(
                              context: context,
                              title: 'Select Filter Type',
                              icon: Icons.filter_alt,
                              options: _filterOptions,
                              selectedValue: _selectedFilterType,
                              isExpanded: _isFilterExpanded,
                              onToggle: () => setState(
                                () => _isFilterExpanded = !_isFilterExpanded,
                              ),
                              onChanged: (value) =>
                                  setState(() => _selectedFilterType = value),
                            ),
                            customTextField(
                              context: context,
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
                        context: context,
                        controller: _wellDepthController,
                        hint: "Well Depth (m)",
                        icon: Icons.height,
                      ),
                      customTextField(
                        context: context,
                        controller: _wellDiameterController,
                        hint: "Well Diameter (m)",
                        icon: Icons.circle,
                      ),
                      const SizedBox(height: 8),
                      buildTextExpandableSelector(
                        context: context,
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
