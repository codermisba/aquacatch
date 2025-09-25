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
  bool _isRoofMaterialExpanded = false; // ✅ added missing variable
  String? _soilType; // holds selected soil type
  bool _isSoilTypeExpanded = false; // expansion state
  // Rooftop shape options (with images)

  final List<Map<String, String>> _filterOptions = [
    {
      'value': 'sandfilter',
      'label': 'Sand Filter',
      'image': 'assets/images/sand_filter.jpg',
    },
    {
      'value': 'charcoalfilter',
      'label': 'Charcoal Filter',
      'image': 'assets/images/charcoal_filter.png',
    },
    {
      'value': 'rccfirstflushfilter',
      'label': 'RCC First Flush Filter',
      'image': 'assets/images/first_flush.png',
    },
    {
      'value': 'meshorscreenfilter',
      'label': 'Mesh or screen filter',
      'image': 'assets/images/mesh_filter.png',
    },
    {
      'value': 'Suggest',
      'label': 'Suggest',
      'image': 'assets/images/select.png',
    },
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

  String? _selectedLocationType;
  bool _isLocationTypeExpanded = false;

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
  final TextEditingController _noOfFloors = TextEditingController(
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

  /// ---------------- Runoff Coefficients ----------------
  Map<String, double> runoffCoeff = {
    "GI sheet": 0.90,
    "Asbestos sheet": 0.80,
    "Tiled roof": 0.75,
    "Concrete roof": 0.75,
  };

  /// ---------------- Construction Costs ----------------
  double plainCementConcreteCost = 1500; // Rs/cum
  double reinforcedCementConcreteCost = 4700; // Rs/cum

  /// ---------------- Plastic Tank Costs ----------------
  Map<String, double> plasticTankCost = {
    "Hindustan": 1.80,
    "Jindal": 1.80,
    "Storex": 0.75,
    "Ganga": 0.75,
  };

  /// ---------------- Load Cost Data ----------------
  Future<List<dynamic>> loadCostData() async {
    final String response = await rootBundle.loadString(
      'assets/rrwhcostdata.json',
    );
    final Map<String, dynamic> data =
        json.decode(response) as Map<String, dynamic>;

    // Extract the list under "Sheet1"
    final List<dynamic> sheetData = data['Sheet1'] as List<dynamic>;
    return sheetData;
  }

  /// ---------------- Harvested Water ----------------
  double calculateWaterHarvested({
    required double annualRainfall,
    required double roofAreaSqm,
    required String roofType,
  }) {
    final coeff = runoffCoeff[roofType] ?? 0.75;
    return (annualRainfall / 1000) * roofAreaSqm * coeff * 1000;
  }

  /// ---------------- Roof Area Range ----------------
  String getRoofAreaRange(double roofAreaSqm) {
    if (roofAreaSqm <= 100) return "<=100";
    if (roofAreaSqm <= 1000) return "101-1000";
    return ">1000";
  }

  /// ---------------- Pipe Length ----------------
  double calculatePipeLength({
    required int numberOfFloors,
    required String roofShape,
    double verticalPerFloor = 3.5,
    double horizontalLength = 10.0,
  }) {
    double totalLength = numberOfFloors * verticalPerFloor;
    if (roofShape.toLowerCase() == "sloped") {
      totalLength += horizontalLength;
    }
    return totalLength;
  }

  /// ---------------- Pipe Cost ----------------
  double calculatePipeCost({
    required double totalLength,
    required double unitCostPerMeter,
  }) {
    return totalLength * unitCostPerMeter;
  }

  /// ---------------- Concrete Cost ----------------
  double calculateConcreteCost({required double volumeCum, bool isRCC = true}) {
    return volumeCum *
        (isRCC ? reinforcedCementConcreteCost : plainCementConcreteCost);
  }

  /// ---------------- Plastic Tank Cost ----------------
  double calculateTankCost({
    required double capacityLiters,
    required String brand,
  }) {
    final costPerLitre = plasticTankCost[brand] ?? 1.0;
    return capacityLiters * costPerLitre;
  }

  /// ---------------- Filter / Installation Cost ----------------
  Future<double> getEstimatedCost({
    required String structure,
    required double roofAreaSqm,
    required String filterType,
  }) async {
    final data = await loadCostData();
    String roofRange = getRoofAreaRange(roofAreaSqm);

    // Search for a matching row
    final match = data.firstWhere(
      (row) =>
          (row['Structure'] as String).toLowerCase() ==
              structure.toLowerCase() &&
          (row['roofarearange'] as String) == roofRange &&
          (row['filtertype'] as String).toLowerCase() ==
              filterType.toLowerCase(),
      orElse: () => {},
    );

    if (match.isEmpty) return 0.0;

    return (match['totalcost'] as num).toDouble();
  }

  /// ---------------- Savings ----------------
  double calculateSavings(double harvestedLiters) {
    return harvestedLiters * 0.5; // ₹0.5 per liter
  }

  /// ---------------- Select Min Cost Filter ----------------
  // Future<String> getMinCostFilter(String structure, double roofAreaSqm) async {
  //   final data = await loadCostData();
  //   String roofRange = getRoofAreaRange(roofAreaSqm);

  //   final filters = data
  //       .where(
  //         (row) =>
  //             row['structure'] == structure &&
  //             row['roofAreaRange'] == roofRange,
  //       )
  //       .toList();

  //   if (filters.isEmpty) return "Mesh Screen Filter";

  //   filters.sort(
  //     (a, b) => (a['totalCost'] as num).compareTo(b['totalCost'] as num),
  //   );
  //   return filters.first['filterType'];
  // }
  Future<Map<String, dynamic>> getMinCostFilter(
    String structure,
    double roofAreaSqm,
  ) async {
    return {"filterType": "Sand Filter", "filterCost": 1000};
  }

  /// ---------------- Pipe Unit Cost ----------------
  double getPipeUnitCost(String pipeType) {
    Map<String, double> pipeCostData = {"PVC": 120, "GI": 300, "HDPE": 150};
    return pipeCostData[pipeType] ?? 150;
  }

  /// ---------------- Navigate and Calculate ----------------
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

    double potentialLiters = calculateWaterHarvested(
      annualRainfall: annualRainfall,
      roofAreaSqm: roofAreaM2,
      roofType: _roofType,
    );

    double annualDemand = dwellers * 135 * 365;

    // ---------------- Select Structure ----------------
    String structure;
    if (selectedAssessment == "AR") {
      double wellDepth = double.tryParse(_wellDepthController.text) ?? 10;
      double wellDiameter = double.tryParse(_wellDiameterController.text) ?? 1;
      structure = "AR Well: $wellDepth m depth, $wellDiameter m diameter";
    } else {
      if (potentialLiters < 0.5 * annualDemand) {
        structure = "Small surface tank";
      } else if (potentialLiters > 4 * annualDemand) {
        structure = "Large underground tank";
      } else {
        structure = "Medium-sized surface tank";
      }
    }

    // ---------------- Filter ----------------
    String filterType = (await getMinCostFilter(
      structure,
      roofAreaM2,
    ))["filterType"];

    // ---------------- Pipe ----------------
    int numberOfFloors = int.tryParse(_noOfFloors.text) ?? 1;
    String roofShape = _selectedRoofShape ?? "Flat Roof";
    String pipeType = "PVC"; // default, or get from user selection

    double pipeLength = calculatePipeLength(
      numberOfFloors: numberOfFloors,
      roofShape: roofShape,
    );
    double pipeCost = calculatePipeCost(
      totalLength: pipeLength,
      unitCostPerMeter: getPipeUnitCost(pipeType),
    );

    // ---------------- Tank ----------------
    String selectedTankBrand = plasticTankCost.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
    double tankCost = calculateTankCost(
      capacityLiters: potentialLiters,
      brand: selectedTankBrand,
    );

    // ---------------- Installation & Total ----------------
    double installationCost =
        pipeCost +
        await getEstimatedCost(
          structure: structure,
          roofAreaSqm: roofAreaM2,
          filterType: filterType,
        );
    double totalCost = tankCost + installationCost;

    double savings = calculateSavings(potentialLiters);

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          annualRainfall: annualRainfall,
          potentialLiters: potentialLiters,
          structure: structure,
          filterType: "Mesh or screen filter",
          pipeType: pipeType,
          pipeLength: pipeLength,
          pipeCost: pipeCost,
          filterCost: 1000,
          tankCost: tankCost,
          installationCost: installationCost,
          totalCost: totalCost,
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
