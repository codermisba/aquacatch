import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:aquacatch/components.dart';

class ArtificialRechargeForm extends StatefulWidget {
  const ArtificialRechargeForm({super.key});

  @override
  _ArtificialRechargeFormState createState() => _ArtificialRechargeFormState();
}

class _ArtificialRechargeFormState extends State<ArtificialRechargeForm> {
  String? _soilType;
  bool _isSoilTypeExpanded = false;

  final List<Map<String, String>> _locationTypeOptions = [
    {'value': 'urban', 'label': 'Urban'},
    {'value': 'suburban', 'label': 'Suburban'},
    {'value': 'rural', 'label': 'Rural'},
  ];

  String? _selectedLocationType;
  bool _isLocationTypeExpanded = false;

  // Common Controllers
  final TextEditingController _locationController = TextEditingController(text: "Solapur");
  final TextEditingController _roofAreaController = TextEditingController(text: "120"); // sqft by default in UI
  final TextEditingController _dwellersController = TextEditingController(text: "5");

  // AR-specific controllers
  final TextEditingController _wellDepthController = TextEditingController(text: "10"); // meters
  final TextEditingController _wellDiameterController = TextEditingController(text: "1"); // meters

  String _city = "Solapur"; // default
  String _roofType = "concrete";

  bool _isLoading = false;

  /// ---------------- Normalizers & helpers ----------------

  /// Normalize structure names to match JSON keys like 'smallsurface', 'mediumsurface', 'largesurface', etc.
  String normalizeStructure(String input) {
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

  /// ---------------- Main calculation & navigation ----------------
  Future<void> _navigateToResult() async {
    setState(() => _isLoading = true);

    // read user inputs
    String location = _locationController.text.trim();
    // int dwellers = int.tryParse(_dwellersController.text) ?? 1; // Not used in AR assessment
    double roofAreaSqft = double.tryParse(_roofAreaController.text) ?? 0;
    double roofAreaSqm = roofAreaSqft * 0.092903; // convert to m²

    // rainfall and aquifer data
    Map<String, dynamic> rainfallData = await _fetchRainfallData(location);
    double annualRainfall = (rainfallData['annual'] ?? 1000.0) as double;

    double groundwaterLevel = await fetchGroundwaterLevel(location);
    final aquiferData = await fetchAquiferData(location);
    String aquiferType = aquiferData?["aquifer"] ?? "Unconfined Aquifer";

    // AR-specific calculations
    double porosity = 0.45; // assume porosity
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
            const SizedBox(height: 10),
            Text("Groundwater Level: ${groundwaterLevel.toStringAsFixed(1)} m"),
            const SizedBox(height: 10),
            Text("Aquifer Type: $aquiferType"),
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
        "Artificial Recharge Assessment",
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
        children: [
          _buildForm(context),
        ],
      ),
    ),
  );
}

  Widget _buildForm(BuildContext context) {
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
                  "Artificial Recharge Assessment",
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

                // AR-specific inputs
                customTextField(
                  context: context,
                  controller: _roofAreaController,
                  hint: "Rooftop Area (sqft)",
                  icon: Icons.roofing,
                ),
                customTextField(
                  context: context,
                  controller: _dwellersController,
                  hint: "Number of Dwellers",
                  icon: Icons.people,
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
