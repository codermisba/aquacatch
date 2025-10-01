import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:aquacatch/components.dart';
import 'result_page.dart';

class RooftopRainwaterHarvestingForm extends StatefulWidget {
  const RooftopRainwaterHarvestingForm({super.key});

  @override
  _RooftopRainwaterHarvestingFormState createState() =>
      _RooftopRainwaterHarvestingFormState();
}

class _RooftopRainwaterHarvestingFormState
    extends State<RooftopRainwaterHarvestingForm> {
  String? _selectedRoofShape;
  bool _isRoofShapeExpanded = false;

  bool _isFilterExpanded = false;
  String? _selectedFilterType;
  bool _isRoofMaterialExpanded = false;

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
      'label': 'Sloping Roof',
      'image': 'assets/images/sloped_roof.png',
    },
  ];

  String? _selectedLocationType;
  bool _isLocationTypeExpanded = false;

  // Common Controllers
  final TextEditingController _locationController =
      TextEditingController();
  final TextEditingController _roofAreaController =
      TextEditingController(); // sqm direct
  final TextEditingController _openSpaceController =
      TextEditingController();
  final TextEditingController _noOfFloors =
      TextEditingController();
  final TextEditingController _dwellersController =
      TextEditingController();

  String _city = "Solapur"; // default
  String _roofType = "concrete";

  File? _roofImage;
  bool _isLoading = false;

  /// ---------------- Normalizers & helpers ----------------
  String normalizeFilter(String? input) {
    if (input == null) return "";
    String s = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (s.contains("sand")) return "sandfilter";
    if (s.contains("charcoal")) return "charcoalfilter";
    if (s.contains("firstflush") || s.contains("rcc"))
      return "rccfirstflushfilter";
    return s;
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
          return double.tryParse(data[0]["groundwaterlevel"].toString()) ?? 15.0;
        }
      }
    } catch (e) {
      debugPrint("Groundwater fetch error: $e");
    }
    return 15.0; // fallback
  }

  /// ---------------- Load RTRWH Cost Data from SheetDB ----------------
  Future<List<dynamic>> loadRooftopCostData() async {
    try {
      final url = Uri.parse("https://sheetdb.io/api/v1/domso538f6dw7");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
      }
    } catch (e) {
      debugPrint("SheetDB fetch error: $e");
    }
    return [];
  }

  /// ---------------- Runoff Coefficients ----------------
  Map<String, double> runoffCoeff = {
    "gi_sheet": 0.90,
    "asbestos": 0.80,
    "tiledroof": 0.75,
    "concrete": 0.75,
  };

  /// ---------------- Costs helpers ----------------
  double calculateWaterHarvested({
    required double annualRainfall,
    required double roofAreaSqm,
    required String roofType,
  }) {
    final coeff = runoffCoeff[roofType.toLowerCase()] ?? 0.70;
    return annualRainfall * roofAreaSqm * coeff;
  }

  double calculatePipeLength({
    required int numberOfFloors,
    required String roofShape,
    double verticalPerFloor = 3.2,
    double horizontalLength = 10.0,
  }) {
    double totalLength = numberOfFloors * verticalPerFloor;
    if (roofShape.toLowerCase().contains("sloped")) {
      totalLength += horizontalLength;
    }
    return totalLength;
  }

  double calculatePipeCost({
    required double totalLength,
    required double unitCostPerMeter,
  }) {
    return totalLength * unitCostPerMeter;
  }

  double calculateTankCost({
    required double capacityLiters,
    required String brand,
  }) {
    final costPerLitre = plasticTankCost[brand] ?? 1.0;
    return capacityLiters * costPerLitre;
  }

  Map<String, double> plasticTankCost = {
    "Hindustan": 1.80,
    "Jindal": 1.80,
    "Storex": 0.75,
    "Ganga": 0.75,
  };

  double calculateSavings(double harvestedLiters) {
    return harvestedLiters * 0.5; // ₹0.5 per liter
  }

  // ✅ simplified fallback
  Map<String, double> getDefaultCosts(String structureKey) {
    switch (structureKey) {
      case "small":
        return {"installation": 2000, "filter": 8000};
      case "medium":
        return {"installation": 4000, "filter": 15000};
      case "large":
        return {"installation": 8000, "filter": 25000};
      default:
        return {"installation": 5000, "filter": 2000};
    }
  }
// ---------------- Pipe Unit Cost fallback ----------------
double getPipeUnitCost(String pipeType) {
  Map<String, double> pipeCostData = {"pvc": 120, "gi": 300, "hdpe": 150};
  return pipeCostData[pipeType.toLowerCase()] ?? 150;
}

  /// ---------------- Main calculation & navigation ----------------
  Future<void> _navigateToResult() async {
    setState(() => _isLoading = true);

    String location = _locationController.text.trim();
    int dwellers = int.tryParse(_dwellersController.text) ?? 1;
    double roofAreaSqm = double.tryParse(_roofAreaController.text) ?? 0;

    Map<String, dynamic> rainfallData = await _fetchRainfallData(location);
    double annualRainfall = (rainfallData['annual'] ?? 1000.0) as double;

    double groundwaterLevel = await fetchGroundwaterLevel(location);
    final aquiferData = await fetchAquiferData(location);
    String aquiferType = aquiferData?["aquifer"] ?? "Unconfined Aquifer";

    double potentialLiters = calculateWaterHarvested(
      annualRainfall: annualRainfall,
      roofAreaSqm: roofAreaSqm,
      roofType: _roofType,
    );

    // ✅ classify structure
    String structureKey;
    if (roofAreaSqm <= 1000 && potentialLiters <= 50000) {
      structureKey = "small";
    } else if ((roofAreaSqm > 1000 && roofAreaSqm <= 5000) ||
        (potentialLiters > 50000 && potentialLiters <= 150000)) {
      structureKey = "medium";
    } else {
      structureKey = "large";
    }

    String filterKey = "Rainy";
    String pipeType = "pvc";

    int numberOfFloors = int.tryParse(_noOfFloors.text) ?? 1;
    String roofShape = _selectedRoofShape ?? "Flat Roof";

    double pipeLength = calculatePipeLength(
      numberOfFloors: numberOfFloors,
      roofShape: roofShape,
    );

    // tank cost (cheapest brand)
    String selectedTankBrand =
        plasticTankCost.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    double tankCost =
        calculateTankCost(capacityLiters: potentialLiters, brand: selectedTankBrand);

    double installationCost = 0.0;
    double filterCost = 0.0;
    double materialCost = 0.0;
    double pipeCost = 0.0;
    double totalCost = 0.0;

    try {
      final data = await loadRooftopCostData();
      final candidates = data.where((row) {
        String rowStructure = (row['Structure'] ?? row['structure'] ?? '')
            .toString()
            .toLowerCase();
        return rowStructure == structureKey;
      }).toList();

      if (candidates.isNotEmpty) {
        Map bestRow = {};
        double bestTotal = double.infinity;

        for (var row in candidates) {
          double inst =
              double.tryParse(row['installationcost'].toString()) ?? 0.0;
          double filtUnit =
              double.tryParse(row['filtercost'].toString()) ?? 0.0;
          int qty = int.tryParse(row['quantityoffilter'].toString()) ?? 1;
          double filt = filtUnit * qty;
          double mat = double.tryParse(row['material'].toString()) ?? 0.0;

          double jsonPipecostPerM =
              double.tryParse(row['pipecost(m)'].toString()) ?? 0.0;
          double rowPipeCost = calculatePipeCost(
            totalLength: pipeLength,
            unitCostPerMeter:
                jsonPipecostPerM > 0 ? jsonPipecostPerM : getPipeUnitCost(pipeType),
          );

          double rowTotal = inst + filt + rowPipeCost + mat + tankCost;

          if (rowTotal < bestTotal) {
            bestTotal = rowTotal;
            bestRow = row;
            installationCost = inst;
            filterCost = filt;
            materialCost = mat;
            pipeCost = rowPipeCost;
            totalCost = rowTotal;
          }
        }
      }

      if (totalCost == 0.0) {
        final defaults = getDefaultCosts(structureKey);
        installationCost = defaults["installation"]!;
        filterCost = defaults["filter"]!;
        totalCost = installationCost + filterCost + pipeCost + materialCost + tankCost;
      }
    } catch (e) {
      debugPrint("Error during cost lookup: $e");
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
          materialCost : materialCost,
          installationCost: installationCost,
          totalCost: totalCost,
          savings: savings,
          dwellers: dwellers,
          tankCost:tankCost,
          roofArea: roofAreaSqm,
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.light
                  ? [
                      primaryColor.withOpacity(0.9),
                      primaryColor,
                    ] // light theme gradient
                  : [Colors.black87, Colors.black], // dark theme gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "RTRWH Assessment",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: true, // ✅ enables back arrow automatically
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context), // ✅ go back
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildForm(context)],
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
                  "Rainwater Harvesting Assessment",
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
                                ),
                                const SizedBox(height: 12),
                                customTextField(
                                  context: context,
                                  controller: _openSpaceController,
                                  hint: "Open Space Area (sqm)",
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

                                // buildExpandableSelector(
                                //   context: context,
                                //   title: 'Select Filter Type',
                                //   icon: Icons.filter_alt,
                                //   options: _filterOptions,
                                //   selectedValue: _selectedFilterType,
                                //   isExpanded: _isFilterExpanded,
                                //   onToggle: () => setState(
                                //     () => _isFilterExpanded =
                                //         !_isFilterExpanded,
                                //   ),
                                //   onChanged: (value) => setState(
                                //     () => _selectedFilterType = value,
                                //   ),
                                // ),
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
                              () =>
                                  _isRoofShapeExpanded = !_isRoofShapeExpanded,
                            ),
                            onChanged: (value) => setState(
                              () => _selectedRoofShape = value ?? "Flat roof",
                            ),
                          ),
                          customTextField(
                            context: context,
                            controller: _roofAreaController,
                            hint: "Rooftop Area (sqm)",
                            icon: Icons.roofing,
                          ),
                          customTextField(
                            context: context,
                            controller: _openSpaceController,
                            hint: "Open Space Area (sqm)",
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
                            onChanged: (value) =>
                                setState(() => _roofType = value ?? "concrete"),
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
                            icon: const Icon(Icons.upload, color: Colors.white),
                            label: const Text(
                              "Upload Roof Photo (optional)",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _pickImage,
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
