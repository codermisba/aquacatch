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
    final url = Uri.parse(
      "https://sheetdb.io/api/v1/x7eb8wzkxon0e/search?district=${Uri.encodeComponent(district.toLowerCase())}",
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
  
// validator functions

String? validateNumber(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final numValue = num.tryParse(value);
  if (numValue == null || numValue <= 0) {
    return 'Enter a valid positive number for $fieldName';
  }
  return null;
}

String? validateCity(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'City name is required';
  }
  final regex = RegExp(r'^[a-zA-Z\s]+$');
  if (!regex.hasMatch(value.trim())) {
    return 'Enter a valid city name (letters only)';
  }
  return null;
}

String? validateDropdown(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return 'Please select $fieldName';
  }
  return null;
}
