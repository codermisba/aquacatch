import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Color scheme
const Color primaryColor = Color(0xFF015670	); // blue
const Color accentColor = Color(0xFF06B6D4); // teal
const Color bgColor = Color(0xFFF3F4F6); // light gre
const Color textColor = Colors.white;
const Color buttonColor = Color(0xFF3595a8);

/// Animated Header
Widget animatedHeader(String animationPath, {double height = 180}) {
  return Lottie.asset(animationPath, height: height);
}



/// Custom TextField
Widget customTextField({
  required TextEditingController controller,
  required String hint,
  bool isPassword = false,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentColor, width: 2)),
      ),
    ),
  );
}

/// Custom Button
Widget customButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      onPressed: onPressed,
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}
