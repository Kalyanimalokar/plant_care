import 'package:flutter/material.dart';
import 'package:plant_care/pages/PlantDetailsPage.dart';
import '../services/firestore.dart';

class ScanPlantPage extends StatefulWidget {
  const ScanPlantPage({super.key});

  @override
  State<ScanPlantPage> createState() => _ScanPlantPageState();
}

class _ScanPlantPageState extends State<ScanPlantPage> {
  final TextEditingController codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _searchPlant() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        //   Convert to uppercase to ensure consistent search
        final searchId = codeController.text.trim().toUpperCase();
        final querySnapshot = await _firestoreService.searchPlantById(searchId);

        if (!mounted) return;

        if (querySnapshot.docs.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No plant found with this ID'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          //   Navigate to plant details page
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PlantDetailsPage(
                  plantDoc: querySnapshot.docs.first,
                )
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error searching for plant $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Plant Code"),
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.tag_outlined,
                size: 64,
                color: Color(0xFF4A6741),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter Plant Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Plant ID',
                  hintText: 'Enter the plant ID (e.g., PLT-20240302-1234',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a plant ID';
                  }
                  if (!value.toUpperCase().startsWith('PLT-')) {
                    return 'Invalid Plant ID format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null: _searchPlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Find Plant',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Where to find the code?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Look for a tag attached to your plant\n'
                            '• IDs start with "PLT-"\n'
                            '• Followed by date (YYYYMMDD)\n'
                            '• Ends with 4 unique digits\n'
                            '• Example: PLT-20240302-1234',
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}