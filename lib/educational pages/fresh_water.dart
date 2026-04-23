import 'package:flutter/material.dart';

class WhyFreshWaterMattersPage extends StatefulWidget {
  const WhyFreshWaterMattersPage({super.key});

  @override
  State<WhyFreshWaterMattersPage> createState() =>
      _WhyFreshWaterMattersPageState();
}

class _WhyFreshWaterMattersPageState extends State<WhyFreshWaterMattersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Why Fresh Water Matters',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0288D1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Section
            _buildSection(
              'Introduction',
              'Fresh water is essential for replenishing underground aquifers, maintaining soil health, and supporting ecosystems and human communities. Understanding how fresh water interacts with soil properties like porosity and permeability is key to sustainable groundwater management.',
              Icons.water,
              const Color(0xFF0277BD),
            ),

            // Concepts Section with Image
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.science,
                          color: Color(0xFF0288D1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Key Concepts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/fresh_water.png', // Corrected path
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Porosity refers to the amount of empty space within soil or rock that can hold water, while permeability is the ability of those spaces to allow water to flow through. Fresh water replenishes these spaces, maintaining aquifer health. However, dirty or polluted water can fill these gaps with sediments and contaminants, reducing porosity and permeability, which impairs groundwater recharge and quality.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      // color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),

            // Importance Section
            _buildSection(
              'Importance of Fresh Water',
              'Maintaining fresh underground aquifers ensures sustainable water supply for drinking, agriculture, and ecosystems. It supports soil permeability, prevents land degradation, and helps communities adapt to water scarcity.',
              Icons.eco,
              const Color(0xFF01579B),
            ),

            // Effects of Contamination Section
            _buildSection(
              'Effects of Contamination',
              'When dirty water containing pollutants and sediments infiltrates the soil, it clogs the pores, reducing porosity and permeability. This leads to decreased groundwater recharge rates, poor water quality, and long-term damage to aquifers.',
              Icons.warning,
              const Color(0xFFB71C1C),
            ),

            // How to Protect Fresh Water Section
            _buildSection(
              'Protecting Fresh Water',
              'Preventing pollution, managing surface runoff, and promoting natural recharge methods help protect the porosity and permeability of soils and aquifers. Sustainable water management practices are essential to preserve fresh water resources.',
              Icons.shield,
              const Color(0xFF0277BD),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              // color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}
