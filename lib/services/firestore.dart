import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plant_care/models/maintenance_activity.dart';
import 'dart:math';


class FirestoreService {
//   Collection reference
  final CollectionReference plants = FirebaseFirestore.instance.collection('plants');
  final CollectionReference records = FirebaseFirestore.instance.collection('records');

  // Generate unique plant ID
  String generatePlantId() {
    final now = DateTime.now();
    final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final random = Random().nextInt(10000).toString().padLeft(4, '0'); // Generates a random 4-digit number
    return "PLT-$timestamp-$random";
  }
  // Create a new plant
  Future<String> addPlant({
    required String plantId,
    required String userId,
    String? organization,
    String? species,
    String? type,
    required DateTime datePlanted,
    required double? latitude,
    required double? longitude,
    String? notes,
  }) async {

    // final String plantId = generatePlantId();

    await plants.doc(plantId).set({
      'plant_id': plantId,
      'owner_id': userId,
      'organization': organization,
      'species': species,
      'type': type,
      'date_planted': datePlanted,
      'location': latitude!= null && longitude != null
          ? GeoPoint(latitude, longitude)
          : null,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    });
    return plantId;
  }

  // Helper method to get the next record index
  Future<int> _getNextRecordIndex(String plantId) async {
    final querySnapshot = await records
        .where('plant_id', isEqualTo: plantId)
        .orderBy('record_index', descending: true)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      return 1; //First record
    }
    final lastRecord = querySnapshot.docs.first.data() as Map<String, dynamic>;
    return (lastRecord['record_index'] as int) + 1;
  }

  // Add plant record (watering/checkup)
  Future<DocumentReference> addPlantRecord({
    required String plantId,
    required String action,
    required String maintainerId,
    String? notes,
  }) async {
    print('Adding record with maintainerId: $maintainerId');
    // Get next record index
    final int recordIndex = await _getNextRecordIndex(plantId);
    print('Adding new record with index: $recordIndex');

    final newRecord = await records.add({
      'plant_id': plantId,
      'action': action,
      'date': FieldValue.serverTimestamp(),
      'notes': notes,
      'record_index': recordIndex,
      'maintainer_id': maintainerId,
    });

  //   if we add 16th record or higher, delete the oldest excess record
    if (recordIndex > 15) {
      // print('Record index > 15, attempting to delete old record');
      final targetIndex = recordIndex - 15;
      // print('loooking for record with index: $targetIndex');

      final oldRecordQuery = await records
          .where('plant_id', isEqualTo: plantId)
          .where('record_index', isEqualTo: targetIndex)
          .limit(1)
          .get();
      // print('Found ${oldRecordQuery.docs.length} records to delete');

      if (oldRecordQuery.docs.isNotEmpty) {
        await oldRecordQuery.docs.first.reference.delete();
        // print('Deleted record with index: $targetIndex');
      }
    }
    return newRecord;
  }

  // Get plant by ID
  Future<DocumentSnapshot> getPlant(String plantId) {
    return plants.doc(plantId).get();
  }

  // Search plant by ID
  Future<QuerySnapshot> searchPlantById(String searchId){
    return plants
        .where('plant_id', isGreaterThanOrEqualTo: searchId)
        .where('plant_id', isLessThanOrEqualTo: searchId + '\uf8ff')
        .get();
  }

  // Get plant records
  Stream<QuerySnapshot> getPlantRecords(String plantId){
    return records
        .where('plant_id', isEqualTo: plantId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Delete Function
  Future<void> deletePlantAndRecords(String plantId) async {
    // Atomic deletion - batch operation
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      // Delete the plant document
      batch.delete(plants.doc(plantId));

      // Get all records for this plant
      final recordSnapshot = await records
        .where('plant_id', isEqualTo: plantId)
        .get();

      // Add all record deletion to batch
      for (var doc in recordSnapshot.docs) {
        batch.delete(doc.reference);
      }
    //   Execute all deletions
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete plant: $e');
    }
  }


  Stream<int> getTotalPlants(String userId) {
    return plants
        .where('owner_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      print('Total plants found: ${snapshot.size}'); // Debug print
      return snapshot.size;
    });
  }

  Stream<Map<String, int>> getPlantTypeStatistics(String userId) {
    return plants
        .where('owner_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      Map<String, int> stats = {};

      // Initialize with 0 for all plant types
      final defaultTypes = [
        'Tree', 'Shrub', 'Flower', 'Herb',
        'Vegetable', 'Indoor Plant', 'Other'
      ];
      for (var type in defaultTypes) {
        stats[type] = 0;
      }

      // Count plants by type
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String? ?? 'Other';
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    });
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Stream<List<MaintenanceActivity>> getRecentActivity(String userId) {
    return records
        .where('maintainer_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MaintenanceActivity(
        plantName: data['plant_id'],
        type: data['action'],
        date: _formatDate(data['date'] as Timestamp),
      );
    }).toList());
  }

  Stream<int> getWateredThisWeek(String userId) {
    final weekAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    return records
        .where('maintainer_id', isEqualTo: userId)
        .where('action', isEqualTo: 'watered')
        .where('date', isGreaterThanOrEqualTo: weekAgo)
        .snapshots()
        .map((snapshot) {
      // print('Watered records this week: ${snapshot.size}');  // Debug print
      // print('Week ago date: ${weekAgo.toDate()}');  // Debug print
      return snapshot.size;
    });
  }

  Stream<int> getNeedingAttention(String userId) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return plants
        .where('owner_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((plantSnapshot) async {
      int count = 0;
      for (var doc in plantSnapshot.docs) {
        final recentRecords = await records
            .where('plant_id', isEqualTo: doc.id)
            .where('date', isGreaterThanOrEqualTo: weekAgo)
            .get();
        if (recentRecords.docs.isEmpty) count++;
      }
      return count;
    });
  }

  Stream<int> getAddedThisMonth(String userId) {
    final monthStart = Timestamp.fromDate(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    ));
    return plants
        .where('owner_id', isEqualTo: userId)
        .where('created_at', isGreaterThanOrEqualTo: monthStart)
        .snapshots()
        .map((snapshot) {
      // print('Plants added this month: ${snapshot.size}');  // Debug print
      // print('Month start date: ${monthStart.toDate()}');  // Debug print
      return snapshot.size;
    });
  }


}

