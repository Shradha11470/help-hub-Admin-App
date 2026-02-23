import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ResolvedDetailPage extends StatelessWidget {
  final int alertId;

  const ResolvedDetailPage({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved SOS Details'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder(
        future: supabase
            .from('sos_alerts')
            .select('*') // ✅ FETCH ALL EXISTING COLUMNS
            .eq('id', alertId)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'ERROR:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final alert = snapshot.data as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoTile('Type', alert['type']),
              _infoTile('Status', alert['status']),
              _infoTile('Assigned Team', alert['assigned_team']),
              _infoTile('Resolved At', alert['resolved_at']),

              const SizedBox(height: 20),

              // ✅ PHOTOS (SAFE)
              if (alert['resolved_photos'] != null &&
                  alert['resolved_photos'] is List &&
                  alert['resolved_photos'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resolution Photos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: (alert['resolved_photos'] as List)
                          .map<Widget>((url) {
                        return Image.network(
                          url,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        );
                      }).toList(),
                    ),
                  ],
                )
              else
                const Text(
                  'No resolution photos available',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value?.toString() ?? '-'),
      ),
    );
  }
}
