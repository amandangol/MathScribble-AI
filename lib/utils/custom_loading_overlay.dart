import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLoadingOverlay extends StatelessWidget {
  final String loadingType;

  const CustomLoadingOverlay({
    super.key,
    required this.loadingType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
              ),
              const SizedBox(height: 16),
              Text(
                loadingType == "recognizing"
                    ? "Recognizing Expression..."
                    : "Solving Expression...",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
