import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceActivity {
  final String plantName;
  final String type;
  final String date;

  MaintenanceActivity({
    required this.plantName,
    required this.type,
    required this.date,
  });
}