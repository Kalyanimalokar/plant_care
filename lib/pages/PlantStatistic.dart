import 'package:flutter/material.dart';
import '../services/firestore.dart';
import '../services/authentication.dart';
import '../models/maintenance_activity.dart';

class PlantStatistics extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  PlantStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUserEmail;
    print('Current user ID: $userId');

    if (userId == null) {
      return const Center(child: Text('Please login to view statistics'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Plants',
              _firestoreService.getTotalPlants(userId),
              Icons.local_florist,
            ),
            _buildStatCard(
              'Watered This Week',
              _firestoreService.getWateredThisWeek(userId),
              Icons.water_drop,
            ),
            _buildStatCard(
              'Need Attention',
              _firestoreService.getNeedingAttention(userId),
              Icons.warning_amber,
              isWarning: true,
            ),
            _buildStatCard(
              'Added This Month',
              _firestoreService.getAddedThisMonth(userId),
              Icons.calendar_today,
            ),
          ],
        ),

        // Plant Types Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.category, color: Color(0xFF4A6741)),
                      SizedBox(width: 8),
                      Text(
                        'Plants by Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  StreamBuilder<Map<String, int>>(
                    stream: _firestoreService.getPlantTypeStatistics(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final stats = snapshot.data!;
                      final nonZeroTypes = stats.entries.where((e) => e.value > 0).toList();

                      if (nonZeroTypes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No plants registered yet'),
                        );
                      }

                      return Column(
                        children: nonZeroTypes.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getTypeIcon(entry.key),
                                    size: 20,
                                    color: Color(0xFF4A6741),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(entry.key),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A6741).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF4A6741),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Recent Activity
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF4A6741)),
                      SizedBox(width: 8),
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  StreamBuilder<List<MaintenanceActivity>>(
                    stream: _firestoreService.getRecentActivity(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No recent activities'),
                        );
                      }

                      return Column(
                        children: snapshot.data!.map((activity) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4A6741).withOpacity(0.1),
                            child: Icon(
                              _getActivityIcon(activity.type),
                              color: const Color(0xFF4A6741),
                              size: 20,
                            ),
                          ),
                          title: Text(activity.plantName),
                          subtitle: Text(activity.date),
                          dense: true,
                        )).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, Stream<int> countStream, IconData icon,
      {bool isWarning = false}) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        print('$title count: ${snapshot.data}'); // Debug print
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isWarning ? Colors.orange : const Color(0xFF4A6741),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.data?.toString() ?? '0',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? Colors.orange : const Color(0xFF4A6741),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Tree':
        return Icons.park;
      case 'Shrub':
        return Icons.nature;
      case 'Flower':
        return Icons.local_florist;
      case 'Herb':
        return Icons.spa;
      case 'Vegetable':
        return Icons.breakfast_dining;
      case 'Indoor Plant':
        return Icons.house;
      default:
        return Icons.category;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'watered':
        return Icons.water_drop;
      case 'fertilized':
        return Icons.eco;
      case 'pruned':
        return Icons.content_cut;
      default:
        return Icons.check_circle;
    }
  }
}