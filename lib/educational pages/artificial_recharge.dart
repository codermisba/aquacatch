import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

class ArtificialRechargePage extends StatefulWidget {
  const ArtificialRechargePage({super.key});

  @override
  State<ArtificialRechargePage> createState() => _ArtificialRechargePageState();
}

class _ArtificialRechargePageState extends State<ArtificialRechargePage> {
  // void _launchURL(String url) async {
  //   if (!await launchUrl(Uri.parse(url))) {
  //     throw 'Could not launch $url';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Artificial Recharge',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _responsiveContainer(
              child: _buildIntroductionSection(context),
            ),
            _responsiveContainer(
              child: _buildMethodsSection(context),
            ),
            _responsiveContainer(
              child: _buildBenefitsSection(context),
            ),
            _responsiveContainer(
              child: _buildComponentsSection(context),
            ),
            _responsiveContainer(
              child: _buildSection(
                context,
                'Environmental Impact',
                'Artificial recharge helps maintain groundwater levels, reduces land subsidence, improves water quality by natural filtration, and supports ecosystem sustainability.',
                Icons.eco,
                const Color.fromARGB(255, 0, 189, 157),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Centered container with max width for web
  Widget _responsiveContainer({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: child,
      ),
    );
  }

 Widget _buildIntroductionSection(BuildContext context) {
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
                color: const Color(0xFF009688).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.science,
                color: Color.fromARGB(255, 0, 188, 157),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Introduction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 188, 157),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ✅ Use AspectRatio to maintain image ratio
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9, // maintain landscape ratio
            child: Image.asset(
              'assets/images/artificial_recharge.png',
              width: double.infinity,
              fit: BoxFit.cover, // fills container without cutting
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Artificial recharge involves techniques like infiltration basins, recharge wells, and percolation tanks to enhance groundwater replenishment by directing surface water into aquifers.',
          style: TextStyle(fontSize: 16, height: 1.6),
        ),
      ],
    ),
  );
}

  Widget _buildSection(
      BuildContext context, String title, String content, IconData icon, Color color) {
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final benefits = [
      {'title': 'Groundwater Replenishment', 'desc': 'Increases underground water storage', 'icon': Icons.water_drop},
      {'title': 'Drought Mitigation', 'desc': 'Supports water availability in dry periods', 'icon': Icons.wb_sunny},
      {'title': 'Reduced Soil Erosion', 'desc': 'Controls surface runoff effectively', 'icon': Icons.terrain},
      {'title': 'Improved Water Quality', 'desc': 'Natural filtration during recharge', 'icon': Icons.verified},
    ];

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
                  color: const Color(0xFF009688).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Color(0xFF009688), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Benefits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 188, 157),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: benefits.map((benefit) {
              double width = MediaQuery.of(context).size.width > 800 ? 220 : (MediaQuery.of(context).size.width / 2 - 24);
              return SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.light
                          ? [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.2),
                            ]
                          : [
                              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                              Theme.of(context).colorScheme.surface.withOpacity(0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(benefit['icon'] as IconData, size: 32, color: const Color(0xFF009688)),
                      const SizedBox(height: 8),
                      Text(
                        benefit['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        benefit['desc'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsSection(BuildContext context) {
    final methods = [
      {'title': 'Recharge Wells', 'desc': 'Wells designed to inject surface water into aquifers', 'color': Colors.teal},
      {'title': 'Infiltration Basins', 'desc': 'Shallow ponds that allow water to percolate underground', 'color': Colors.green},
      {'title': 'Percolation Tanks', 'desc': 'Reservoirs that store water for slow infiltration', 'color': Colors.orange},
      {'title': 'Check Dams', 'desc': 'Small barriers to slow water flow and increase infiltration', 'color': Colors.purple},
    ];

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
                  color: const Color(0xFF00796B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water, color: Color.fromARGB(255, 0, 188, 157), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recharge Methods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 188, 157),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: methods.map((method) {
              double width = MediaQuery.of(context).size.width > 800 ? 300 : double.infinity;
              return SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (method['color'] as Color).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (method['color'] as Color).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (method['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.opacity, color: method['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              method['desc'] as String,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
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
    );
  }

  Widget _buildComponentsSection(BuildContext context) {
    final components = [
      {'name': 'Recharge Wells', 'desc': 'Wells to inject water underground'},
      {'name': 'Infiltration Basins', 'desc': 'Areas for water percolation'},
      {'name': 'Percolation Tanks', 'desc': 'Reservoirs for slow infiltration'},
      {'name': 'Check Dams', 'desc': 'Barriers to slow water flow'},
      {'name': 'Recharge Shafts', 'desc': 'Vertical shafts for water entry'},
      {'name': 'Filter Media', 'desc': 'Materials to purify water before recharge'},
    ];

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
                  color: const Color(0xFF004D40).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, color: Color.fromARGB(255, 0, 188, 157), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'System Components',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 188, 157)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(components.length, (index) {
              final component = components[index];
              double width = MediaQuery.of(context).size.width > 800 ? 300 : double.infinity;
              return SizedBox(
                width: width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(component['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(component['desc']!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
