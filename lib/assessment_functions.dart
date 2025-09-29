import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//Aquifer data
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


//rainfall data

   
 
 // ground water level

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

  
