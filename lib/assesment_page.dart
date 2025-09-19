import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  AssessmentPageState createState() => AssessmentPageState();
}

class AssessmentPageState extends State<AssessmentPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _familyMembersController = TextEditingController();

  // Separate variables for each section
  String? _selectedRoofShape; // Flat/Sloped
  String? _selectedRoofMaterial; // Concrete/GI Sheet/Asbestos
  String? _selectedFilterType;
  List<String> _selectedTanks = [];

  bool _isRoofShapeExpanded = false;
  bool _isRoofMaterialExpanded = false;
  bool _isFilterExpanded = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Rooftop shape options (with images)
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

  // Rooftop material options (text only)
  final List<Map<String, String>> _rooftypeOptions = [
    {'value': 'concrete', 'label': 'Concrete'},
    {'value': 'gi_sheet', 'label': 'GI Sheet'},
    {'value': 'asbestos', 'label': 'Asbestos'},
  ];

  // Filter options (with images)
  final List<Map<String, String>> _filterOptions = [
    {
      'value': 'Sand Filter',
      'label': 'Sand Filter',
      'image': 'assets/images/sand_filter.jpg',
    },
    {
      'value': 'Charcoal Filter',
      'label': 'Charcoal Filter',
      'image': 'assets/images/charcoal_filter.png',
    },
    {
      'value': 'RCC First Flush Filter',
      'label': 'RCC First Flush Filter',
      'image': 'assets/images/first_flush.png',
    },
  ];

  final List<String> _tankOptions = [
    'Concrete Tank',
    'Plastic Tank',
    'Underground Tank',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _familyMembersController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report generated successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ------------------ Reusable Expandable Selector ------------------
  Widget _buildExpandableSelector({
    required String title,
    required IconData icon,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Icon(icon, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        selectedValue ?? title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isExpanded)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: options.map((option) {
                  final isSelected = selectedValue == option['value'];
                  return GestureDetector(
                    onTap: () => onChanged(option['value']),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 32,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey[100],
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (option['image'] != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                option['image']!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            option['label'] ?? option['value']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.blue : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Roof Shape (with images)
                  _buildExpandableSelector(
                    title: 'Select Roof Shape',
                    icon: Icons.home,
                    options: _rooftopOptions,
                    selectedValue: _selectedRoofShape,
                    isExpanded: _isRoofShapeExpanded,
                    onToggle: () => setState(
                      () => _isRoofShapeExpanded = !_isRoofShapeExpanded,
                    ),
                    onChanged: (value) =>
                        setState(() => _selectedRoofShape = value),
                  ),
                  const SizedBox(height: 20),

                  // Roof Material (text only)
                  _buildExpandableSelector(
                    title: 'Select Roof Material',
                    icon: Icons.roofing,
                    options: _rooftypeOptions,
                    selectedValue: _selectedRoofMaterial,
                    isExpanded: _isRoofMaterialExpanded,
                    onToggle: () => setState(
                      () => _isRoofMaterialExpanded = !_isRoofMaterialExpanded,
                    ),
                    onChanged: (value) =>
                        setState(() => _selectedRoofMaterial = value),
                  ),
                  const SizedBox(height: 20),

                  // Filter Type
                  _buildExpandableSelector(
                    title: 'Select Filter Type',
                    icon: Icons.filter_alt,
                    options: _filterOptions,
                    selectedValue: _selectedFilterType,
                    isExpanded: _isFilterExpanded,
                    onToggle: () =>
                        setState(() => _isFilterExpanded = !_isFilterExpanded),
                    onChanged: (value) =>
                        setState(() => _selectedFilterType = value),
                  ),

                  const SizedBox(height: 20),

                  // Family Members
                  _buildSectionCard(
                    icon: Icons.people,
                    title: 'Family Members',
                    child: TextFormField(
                      controller: _familyMembersController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        'Enter number of members',
                      ).copyWith(prefixIcon: const Icon(Icons.person)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of family members';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tanks
                  _buildSectionCard(
                    icon: Icons.storage,
                    title: 'Tank Types (Multi-selection)',
                    child: Column(
                      children: _tankOptions.map((tank) {
                        return CheckboxListTile(
                          title: Text(tank),
                          value: _selectedTanks.contains(tank),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedTanks.add(tank);
                              } else {
                                _selectedTanks.remove(tank);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, // Makes button full width
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.assessment),
                      label: const Text(
                        'Generate Report',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
