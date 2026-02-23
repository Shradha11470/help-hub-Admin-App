import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Resolved_details.dart'; // ✅ keep only once

final supabase = Supabase.instance.client;

class ResolvedPage extends StatelessWidget {
  const ResolvedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved SOS Requests'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('sos_alerts').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          // ✅ FILTER COMPLETED
          final completedAlerts = snapshot.data!
              .where((row) => row['status'] == 'completed')
              .toList();

          // ✅ SORT (LATEST FIRST)
          completedAlerts.sort((a, b) {
            final aTime = a['resolved_at'];
            final bTime = b['resolved_at'];

            if (aTime != null && bTime != null) {
              return DateTime.parse(bTime)
                  .compareTo(DateTime.parse(aTime));
            }
            return (b['id'] as int).compareTo(a['id'] as int);
          });

          final resolvedCount = completedAlerts.length;

          return Column(
            children: [
              // ===== COUNT HEADER =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Text(
                  'Resolved SOS Alerts: $resolvedCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              // ===== LIST =====
              Expanded(
                child: resolvedCount == 0
                    ? const Center(child: Text('No resolved SOS requests'))
                    : ListView.builder(
                        itemCount: resolvedCount,
                        itemBuilder: (context, index) {
                          final alert = completedAlerts[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 30,
                              ),
                              title: Text(
                                alert['type'] ?? 'SOS Alert',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Assigned Team: ${alert['assigned_team'] ?? '-'}'),
                                  Text(
                                      'Resolved at: ${alert['resolved_at'] ?? '-'}'),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResolvedDetailPage(
                                      alertId: alert['id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
