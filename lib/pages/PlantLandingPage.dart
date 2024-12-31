import 'package:flutter/material.dart';
import 'package:plant_care/pages/PlantStatistic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/authentication.dart';
import 'LoginPage.dart';
import 'ScanPlantPage.dart';
import 'NewPlantPage.dart';

class PlantLandingPage extends StatelessWidget {
  const PlantLandingPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final AuthService authService = AuthService();
      await authService.signOut();

      if (!context.mounted) return;
      // Navigate to login page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plant Care"),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4, // More height
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation container with fixed height
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.25, // Animation takes 25% of screen height
                      child: Lottie.asset(
                        'asset/PlantAnimation.json',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Spacing between animation and text
                    const SizedBox(height: 20),

                    // Welcome text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Welcome to Plant Care",
                          style: TextStyle(
                            color: Color(0xFF1B4D3E),
                            fontSize: 14,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Track & Nurture Your Green Space",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            textStyle: const TextStyle(
                              color: Color(0xFF1B4D3E),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Statistics Section
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
              //   child: PlantStatistics(),
              // ),

              // Action Buttons Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New Plant Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewPlantPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6741),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text(
                            "New Plant",
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scan/Enter Code Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanPlantPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(
                          color: Color(0xFF4A6741),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner),
                          SizedBox(width: 8),
                          Text(
                            "Enter Plant Code",
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A6741),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom padding to avoid overflow with navigation bar
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}