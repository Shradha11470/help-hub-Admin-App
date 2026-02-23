import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// ================= RESCUE OPERATIONS =================

class RescueOperationsPage extends StatefulWidget {
  const RescueOperationsPage({super.key});

  @override
  State<RescueOperationsPage> createState() => _RescueOperationsPageState();
}

class _RescueOperationsPageState extends State<RescueOperationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rescue Operations',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('sos_alerts')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!;

          /// 🔴 PENDING
          final pending = alerts
              .where(
                (a) =>
                    a['assigned_team'] == null &&
                    (a['status'] == null || a['status'] == 'pending'),
              )
              .toList();

          /// 🟠 ACTIVE
          final active = alerts
              .where(
                (a) => a['assigned_team'] != null && a['status'] == 'assigned',
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Pending Assignment', pending.length),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  const Text(
                    'No pending alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ...pending.map((a) => _pendingCard(context, a)),
                const SizedBox(height: 30),
                _title('Active Rescues', active.length),
                const SizedBox(height: 12),
                if (active.isEmpty)
                  const Text(
                    'No active rescues',
                    style: TextStyle(color: Colors.grey),
                  ),
                ...active.map((a) => _activeCard(a)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= TITLE =================
  Widget _title(String t, int c) {
    return Row(
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.red,
          child: Text(
            '$c',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// ================= PENDING CARD =================
  Widget _pendingCard(BuildContext context, Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a['type'] ?? 'OTHER',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '📍 ${a['latitude']} , ${a['longitude']}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: const Text('Assign Rescue Team'),
              onPressed: () async {
                int sosId;
                try {
                  sosId = a['id'] is int ? a['id'] : int.parse(a['id'].toString());
                } catch (e) {
                  print('Invalid sosId: ${a['id']}');
                  return;
                }

                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamSelectionPage(sosId: sosId),
                  ),
                );

                /// 🔥 FORCE REBUILD AFTER ASSIGNMENT
                if (updated == true) {
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= ACTIVE CARD =================
  Widget _activeCard(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a['assigned_team'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ASSIGNED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            a['type'],
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '📍 ${a['latitude']} , ${a['longitude']}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Started few hours ago',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// ================= TEAM SELECTION =================

class TeamSelectionPage extends StatelessWidget {
  final int sosId;
  const TeamSelectionPage({super.key, required this.sosId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(title: const Text('Select Team')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('teams').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (_, i) {
              final t = teams[i];
              return ListTile(
                title: Text(
                  t['team_name'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  t['leader_name'],
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  try {
                    // ✅ Update alert without null check
                    await supabase
                        .from('sos_alerts')
                        .update({
                          'assigned_team': t['team_name'],
                          'status': 'assigned',
                        })
                        .eq('id', sosId);

                    // Send notification if phone exists
                    if (t['leader_phone'] != null) {
                      await supabase.functions.invoke(
                        'send-team-notification',
                        body: {
                          'phone': t['leader_phone'],
                          'message':
                              '🚨 Emergency Assigned!\nTeam: ${t['team_name']}\nPlease check Rescue App immediately.',
                        },
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Team "${t['team_name']}" Assigned Successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pop(context, true); // refresh parent
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to assign team: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabase = Supabase.instance.client;

/// ================= RESCUE OPERATIONS =================

// class RescueOperationsPage extends StatefulWidget {
//   const RescueOperationsPage({super.key});

//   @override
//   State<RescueOperationsPage> createState() => _RescueOperationsPageState();
// }

// class _RescueOperationsPageState extends State<RescueOperationsPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B1020),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Rescue Operations',
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: supabase
//             .from('sos_alerts')
//             .stream(primaryKey: ['id'])
//             .order('created_at', ascending: false),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final alerts = snapshot.data!;

//           /// 🔴 PENDING
//           final pending = alerts
//               .where((a) =>
//                   a['assigned_team'] == null &&
//                   (a['status'] == null || a['status'] == 'pending'))
//               .toList();

//           /// 🟠 ACTIVE
//           final active = alerts
//               .where(
//                   (a) => a['assigned_team'] != null && a['status'] == 'assigned')
//               .toList();

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _title('Pending Assignment', pending.length),
//                 const SizedBox(height: 12),

//                 if (pending.isEmpty)
//                   const Text(
//                     'No pending alerts',
//                     style: TextStyle(color: Colors.grey),
//                   ),

//                 ...pending.map((a) => _pendingCard(context, a)),

//                 const SizedBox(height: 30),

//                 _title('Active Rescues', active.length),
//                 const SizedBox(height: 12),

//                 if (active.isEmpty)
//                   const Text(
//                     'No active rescues',
//                     style: TextStyle(color: Colors.grey),
//                   ),

//                 ...active.map((a) => _activeCard(a)),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   /// ================= TITLE =================
//   Widget _title(String t, int c) {
//     return Row(
//       children: [
//         Text(
//           t,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(width: 8),
//         CircleAvatar(
//           radius: 10,
//           backgroundColor: Colors.red,
//           child: Text(
//             '$c',
//             style: const TextStyle(fontSize: 12, color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }

//   /// ================= PENDING CARD =================
//   Widget _pendingCard(BuildContext context, Map<String, dynamic> a) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1F2E),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.red),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             a['type'] ?? 'OTHER',
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '📍 ${a['latitude']} , ${a['longitude']}',
//             style: const TextStyle(color: Colors.white70),
//           ),
//           const SizedBox(height: 14),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               child: const Text('Assign Rescue Team'),
//               onPressed: () async {
//                 final updated = await Navigator.push<bool>(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => TeamSelectionPage(sosId: a['id']),
//                   ),
//                 );

//                 /// 🔥 FORCE REBUILD AFTER ASSIGNMENT
//                 if (updated == true) {
//                   setState(() {});
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ================= ACTIVE CARD =================
//   Widget _activeCard(Map<String, dynamic> a) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 18),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF141414),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.orange, width: 1.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// TOP ROW
//           Row(
//             children: [
//               Container(
//                 height: 40,
//                 width: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade900,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.shield, color: Colors.blue),
//               ),
//               const SizedBox(width: 12),

//               Expanded(
//                 child: Text(
//                   a['assigned_team'],
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),

//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.orange,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Text(
//                   'ASSIGNED',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 14),

//           /// TYPE
//           Text(
//             a['type'],
//             style: const TextStyle(
//               color: Colors.orange,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),

//           const SizedBox(height: 6),

//           /// LOCATION
//           Text(
//             '📍 ${a['latitude']} , ${a['longitude']}',
//             style: const TextStyle(color: Colors.white70),
//           ),

//           const SizedBox(height: 8),

//           const Text(
//             'Started few hours ago',
//             style: TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// ================= TEAM SELECTION =================

// class TeamSelectionPage extends StatelessWidget {
//   final int sosId;
//   const TeamSelectionPage({super.key, required this.sosId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B1020),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1A1F2E),
//         title: const Text(
//           'Select Team',
//           style: TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: supabase
//             .from('teams')
//             .stream(primaryKey: ['id'])
//             .eq('status', 'available'),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final teams = snapshot.data!;

//           if (teams.isEmpty) {
//             return const Center(
//               child: Text(
//                 "No teams available",
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             );
//           }

//           return ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: teams.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 12),
//             itemBuilder: (_, i) {
//               final t = teams[i];
//               return Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1A1F2E),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.blueAccent),
//                 ),
//                 child: ListTile(
//                   title: Text(
//                     t['team_name'],
//                     style: const TextStyle(
//                         color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     t['leader_name'],
//                     style: const TextStyle(color: Colors.white70),
//                   ),
//                   trailing: const Icon(
//                     Icons.arrow_forward_ios,
//                     color: Colors.white70,
//                     size: 16,
//                   ),
//                   onTap: () async {
//                     await supabase.from('sos_alerts').update({
//                       'assigned_team': t['team_name'],
//                       'status': 'assigned',
//                     }).eq('id', sosId);

//                     // 🔔 CALL NOTIFICATION FUNCTION
//                     await supabase.functions.invoke(
//                       'send-team-notification',
//                       body: {
//                         'phone': t['leader_phone'],
//                         'message':
//                             '🚨 Emergency Assigned!\nTeam: ${t['team_name']}\nPlease check Rescue App immediately.',
//                       },
//                     );

//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Team Assigned'),
//                           backgroundColor: Colors.green,
//                         ),
//                       );

//                       /// 🔥 RETURN TRUE TO PARENT
//                       Navigator.pop(context, true);
//                     }
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
