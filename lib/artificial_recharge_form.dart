import 'package:aquacatch/assessment_functions.dart';
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
  final _formKey = GlobalKey<FormState>();

  String? _selectedRoofShape;
  String? _soilType;
  bool _isRoofMaterialExpanded = false;
  bool _isRoofShapeExpanded = false;
  bool _isSoilTypeExpanded = false;

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

  Future<List<dynamic>> loadARCostData() async {
    final String response = await rootBundle.loadString(
      'assets/arcostdata.json',
    );
    final Map<String, dynamic> data = json.decode(response);
    return data['Sheet1'] as List<dynamic>;
  }

  /// ---------------- Main calculation & navigation ----------------
  Future<void> _navigateToResult() async {
    setState(() => _isLoading = true);

    double roofAreaSqm = double.tryParse(_roofAreaController.text) ?? 0;

    double runoffCoeffAR = runoffCoeff[_roofType?.toLowerCase()] ?? 0.75;

    // Simple recharge estimation
    double porosity = 0.45;
    double rechargeLiters = porosity * 1000 * roofAreaSqm * runoffCoeffAR;

    // Load AR cost data
    List<dynamic> data = await loadARCostData();
    Map<String, dynamic>? match;
    try {
      match = data.firstWhere(
        (row) => (row['Structure'] ?? '').toString().toLowerCase() == "pit",
      );
    } catch (_) {
      match = null;
    }

    double totalCost = 16791.5; // fallback
    if (match != null) {
      totalCost = double.tryParse(match['totalcost'].toString()) ?? totalCost;
    }

    double groundwaterLevel = await fetchGroundwaterLevel(_city);

    setState(() => _isLoading = false);

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
                                      buildExpandableSelector(
                                        context: context,
                                        title: 'Select Soil Type',
                                        validator: (value) => validateDropdown(value, 'soil Type'),
                                        icon: Icons.landscape,
                                        options: [
                                          {
                                            'value': 'Alluvial soil',
                                            'label': 'Alluvial soil',
                                            'image': 'assets/images/alluvial.jpg',
                                          },
                                          {
                                            'value': 'Black soil (Regur)',
                                            'label': 'Black soil (Regur)',
                                            'image':
                                                'assets/images/black_soil.jpg',
                                          },
                                          {
                                            'value': 'Red and Yellow soil',
                                            'label': 'Red and Yellow soil',
                                            'image':
                                                'assets/images/red_yellow.JPG',
                                          },
                                          {
                                            'value': 'Laterite soil',
                                            'label': 'Laterite soil',
                                            'image':
                                                'assets/images/laterite_soil.jpg',
                                          },
                                          {
                                            'value': 'Arid (Desert) soil',
                                            'label': 'Arid (Desert) soil',
                                            'image': 'assets/images/arid.jpg',
                                          },
                                          {
                                            'value': 'Forest soil',
                                            'label': 'Forest soil',
                                            'image': 'assets/images/forest.jpg',
                                          },
                                          {
                                            'value': 'Saline soil',
                                            'label': 'Saline soil',
                                            'image': 'assets/images/saline.jpg',
                                          },
                                          {
                                            'value': 'Peaty soil',
                                            'label': 'Peaty soil',
                                            'image': 'assets/images/peaty.jpg',
                                          },
                                        ],
                                        selectedValue: _soilType,
                                        isExpanded: _isSoilTypeExpanded,
                                        onToggle: () => setState(
                                          () => _isSoilTypeExpanded =
                                              !_isSoilTypeExpanded,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _soilType =
                                              value ?? "Alluvial soil",
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
                                buildExpandableSelector(
                                  context: context,
                                  title: 'Select Soil Type',
                                  validator: (value) => validateDropdown(value, 'Roof Type'),
                                  icon: Icons.landscape,
                                  options: [
                                    {
                                      'value': 'Alluvial soil',
                                      'label': 'Alluvial soil',
                                      'image': 'assets/images/alluvial.jpg',
                                    },
                                    {
                                      'value': 'Black soil (Regur)',
                                      'label': 'Black soil (Regur)',
                                      'image': 'assets/images/black_soil.jpg',
                                    },
                                    {
                                      'value': 'Red and Yellow soil',
                                      'label': 'Red and Yellow soil',
                                      'image': 'assets/images/red_yellow.JPG',
                                    },
                                    {
                                      'value': 'Laterite soil',
                                      'label': 'Laterite soil',
                                      'image': 'assets/images/laterite_soil.jpg',
                                    },
                                    {
                                      'value': 'Arid (Desert) soil',
                                      'label': 'Arid (Desert) soil',
                                      'image': 'assets/images/arid.jpg',
                                    },
                                    {
                                      'value': 'Forest soil',
                                      'label': 'Forest soil',
                                      'image': 'assets/images/forest.jpg',
                                    },
                                    {
                                      'value': 'Saline soil',
                                      'label': 'Saline soil',
                                      'image': 'assets/images/saline.jpg',
                                    },
                                    {
                                      'value': 'Peaty soil',
                                      'label': 'Peaty soil',
                                      'image': 'assets/images/peaty.jpg',
                                    },
                                  ],
                                  selectedValue: _soilType,
                                  isExpanded: _isSoilTypeExpanded,
                                  onToggle: () => setState(
                                    () => _isSoilTypeExpanded =
                                        !_isSoilTypeExpanded,
                                  ),
                                  onChanged: (value) => setState(
                                    () => _soilType = value ?? "Alluvial soil",
                                  ),
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
