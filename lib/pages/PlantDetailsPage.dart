import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plant_care/Pages/PlantLandingPage.dart';
import '../services/firestore.dart';
import 'PlantQRCodeWidget.dart';
import 'AddRecordPage.dart';

class PlantDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot plantDoc;
  final FirestoreService _firestoreService = FirestoreService();

  PlantDetailsPage({
    super.key,
    required this.plantDoc,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date not available';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'watered':
        return Icons.water_drop;
      case 'fertilized':
        return Icons.eco;
      case 'pruned':
        return Icons.content_cut;
      case 'checkup':
        return Icons.check_circle;
      default:
        return Icons.event_note; // Default icon for unknown actions
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = plantDoc.data() as Map<String, dynamic>;
    final GeoPoint? location = data['location'] as GeoPoint?;
    final Timestamp? datePlanted = data['date_planted'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Details'),
        backgroundColor: const Color(0xFF4A6741),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              // Store the result of the confirmation dialog
              final bool? shouldDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Plant'),
                    content: const Text(
                        'Are you sure you want to delete this plant? '
                        'This will permanently delete the plant and all its maintenance records.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              // If user confirmed deletion
              if (shouldDelete == true && context.mounted) {
                try {
                  // Show loading indicator
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Delete plant and its records
                  await _firestoreService.deletePlantAndRecords(
                      data['plant_id'] as String
                  );

                  if (!context.mounted) return;

                  Navigator.of(context).pop(); // Remove loading indicator

                  // Navigate to landing page
                  await Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const PlantLandingPage(),
                    ),
                        (route) => false,
                  );

                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Plant deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Remove loading indicator

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting plant: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant ID Card
              Card(
                child: ListTile(
                  title: const Text(
                    'Plant ID',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    data['plant_id'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6741),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add planter Information Card
              Card(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registration Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const Divider(),
                        _detailRow('Registered By', data['owner_id'] ?? 'Unknown'),
                          if (data['organization'] != null && data['organization'].toString().isNotEmpty)
                            _detailRow('Organization', data['organization']),
                      ],
                    ),
                ),
              ),
              const SizedBox(height: 16),
              // Plant QR code Card
              PlantQRCode(plantId: data['plant_id'] as String),
              const SizedBox(height: 16),
              // Plant Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plant Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _detailRow('Species', data['species'] as String? ?? 'Not specified'),
                      _detailRow('Type', data['type'] as String? ?? 'Not specified'),
                      _detailRow('Date Planted', _formatDate(datePlanted)),
                      if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                        _detailRow('Notes', data['notes'] as String),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Location Card
              if (location != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _detailRow('Latitude', location.latitude.toStringAsFixed(6)),
                        _detailRow('Longitude', location.longitude.toStringAsFixed(6)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Records Section
              const Text(
                'Maintenance Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getPlantRecords(data['plant_id']),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // print('Error in StreamBuilder: ${snapshot.error}');
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading records: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final records = snapshot.data?.docs ?? [];

                  if (records.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No maintenance records yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index].data() as Map<String, dynamic>;
                      final Timestamp? recordDate = record['date'] as Timestamp?;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            _getActionIcon(record['action'] as String? ?? 'unknown'),
                            color: const Color(0xFF4A6741),
                          ),
                          title: Text(record['action'] as String? ?? 'Unknown Action'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(recordDate)),
                              Text('Maintained by: ${record['maintainer_id'] ?? 'Unknown'}'),
                              if (record['notes'] != null)
                                Text(record['notes'] as String),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A6741),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRecordPage(
                plantId: data['plant_id'] as String,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}