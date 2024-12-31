import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore.dart';
import '../services/authentication.dart';


class NewPlantPage extends StatefulWidget {
  const NewPlantPage({super.key});

  @override
  State<NewPlantPage> createState() => _NewPlantPageState();
}

class _NewPlantPageState extends State<NewPlantPage> {
  final _formkey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _notesController = TextEditingController();
  final _organizationController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _selectedType;
  Position? _currentPosition;
  bool _isLoading = false;
  DateTime? _datePlanted;
  String? _plantId;
  String? _currentUserEmail;

  // Initialize FireStore Service
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _speciesList = [
    'Allegheny serviceberry',
    'American hornbeam',
    'Northern catalpa',
    'Persimmon',
    'Kentucky coffeetree',
    'Bald cypress',
    'Northern pecan',
    'Other (Type manually)',
  ];

  final List<String> _plantType = [
    'Tree',
    'Shrub',
    'Flower',
    'Herb',
    'Vegetable',
    'Indoor Plant',
    'Other'
  ];


  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation
  );

  @override
  void initState(){
    super.initState();
  //   Generate plant ID when page loads
    _plantId = _firestoreService.generatePlantId();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUserEmail = _authService.currentUserEmail;
    setState(() {});
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _notesController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try{
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied!");
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _datePlanted ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
    );
    if (picked != null && picked != _datePlanted) {
      setState(() {
        _datePlanted = picked;
      });
    }
  }

  Future<void> _savePlant() async {
    if (_formkey.currentState!.validate()) {
      if (_currentPosition == null){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please get the current location first!")),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

      try {
        final String? userId = _authService.currentUserEmail;
        if (userId == null) {
          throw Exception("No user logged in");
        }
        await _firestoreService.addPlant(
            plantId: _plantId!,
            userId: userId,
            organization: _organizationController.text.isEmpty
                ? null
                : _organizationController.text,
            species: _speciesController.text,
            type: _selectedType!,
            datePlanted: _datePlanted!,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            notes: _notesController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Plant registered successfully! ID: $_plantId"),
              duration: const Duration(seconds: 5),
          ),
        );

      //   Navigate back after successful save
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering plant: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Plant"),
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //  Plant ID Display
                  Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Plant ID",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox( height: 8),
                            Text(
                              _plantId ?? 'Generating...',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A6741),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Save this ID for future reference",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Registered By",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUserEmail ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A6741),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Organization Field optional
                  TextFormField(
                    controller: _organizationController,
                    decoration: InputDecoration(
                      labelText: "Organization (Optional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.business)
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Species Field
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                      //   Dropdown for quick selection
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select or type species'),
                                  value: null,
                                  items: _speciesList.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                        child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue == 'Other (Type manually)') {
                                      _speciesController.clear();
                                    } else if (newValue != null) {
                                      _speciesController.text = newValue;
                                    }
                                  },
                              ),
                          ),
                        ),
                        const Divider(height: 1),
                      //   Text field for manual input
                        TextFormField(
                          controller: _speciesController,
                          decoration: InputDecoration(
                            hintText: 'Type Species name',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            prefixIcon: const Icon(Icons.science),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Plant Type Dropdown
                  DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: "Plant Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _plantType.map((String type) {
                        return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type)
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please select a plant type";
                        }
                        return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date Planted Field
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Date Planted",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _datePlanted != null
                              ? "${_datePlanted!.day}/${_datePlanted!.month}/${_datePlanted!.year}"
                              : "",
                        ),
                        validator: (value) {
                          if (_datePlanted == null) {
                            return "Please select a Planting date";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Notes",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Button

                  ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.location_on),
                      label: Text(_isLoading ? "Getting Location..." : "Get Current Location",
                      style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6741),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const Text(
                                  "Location Details",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                                  'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null: _savePlant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6741),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Register Plant",
                          style: TextStyle(fontSize: 18),
                      ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
