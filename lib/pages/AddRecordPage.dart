import 'package:flutter/material.dart';
import '../services/firestore.dart';
import '../services/authentication.dart';

class AddRecordPage extends StatefulWidget {
  final String plantId;

  AddRecordPage({
    super.key,
    required this.plantId,
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final AuthService _authService = AuthService();
  String _selectAction = 'watered'; //the defaukt action will be watered
  bool _isLoading = false;
  String? _currentUserEmail;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUserEmail = _authService.currentUserEmail;
    setState(() {});
  }

  final List<Map<String, dynamic>> _actionTypes = [
    {
      'value': 'watered',
      'label': 'Watered Plant',
      'icon': Icons.water_drop,
    },
    {
      'value': 'checkup',
      'label': 'General Checkup',
      'icon': Icons.check_circle,
    },
    {
      'value': 'fertilized',
      'label': 'Added Fertilizer',
      'icon': Icons.eco,
    },
    {
      'value': 'pruned',
      'label': 'Pruned Plant',
      'icon': Icons.content_cut,
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? userId = _authService.currentUserEmail;
        if (userId == null) {
          throw Exception("No user logged in");
        }
        await _firestoreService.addPlantRecord(
            plantId: widget.plantId,
            action: _selectAction,
            notes:  _notesController.text.trim(),
            maintainerId: userId,
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record added Successfully')),
        );

        Navigator.pop(context); // we return to the previous page after we have recorded our action
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding record $e')),
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
        title: const Text('Add Maintenance Record'),
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  //   Plant id display
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Plant ID',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.plantId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A6741),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  //   Action Type Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select Action Type",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                                _actionTypes.length,
                                (index) => RadioListTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          _actionTypes[index]['icon'] as IconData,
                                          color: const Color(0xFF4A6741),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_actionTypes[index]['label'] as String),
                                      ],
                                    ),
                                    value: _actionTypes[index]['value'] as String,
                                    groupValue: _selectAction,
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectAction = value;
                                        });
                                      }
                                    },
                                  activeColor: const Color(0xFF4A6741),
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  //   Notes Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Notes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: "Add any observation or notes...",
                                  border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    //   Save Button
                    ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A6741),
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
                          "Save Record",
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
