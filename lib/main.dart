import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Rescue_operation/Rescue_operation.dart';
import 'Teams/Teams.dart';
import 'Resolved/ResolvedPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iqwbgmlpkfaqytjqcphh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlxd2JnbWxwa2ZhcXl0anFjcGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTMwNzEsImV4cCI6MjA4MTE2OTA3MX0.HzwheFwYCrjUJ6KRQfAoMkrJU60GoMD2Y9uJZMX__nY',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

/* ================= APP ================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1020),
      ),
      home: const MainNavigation(),
    );
  }
}

/* ================= MAIN NAVIGATION ================= */

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    Center(child: Text('Profile')),
    RescueOperationsPage(),
    Teams(),
    ResolvedPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 244, 130, 130),
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Rescue Operations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Resolved'),
        ],
      ),
    );
  }
}

/* ================= DASHBOARD PAGE ================= */

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Response',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Command Center',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
      body: const DashboardContent(),
    );
  }
}

/* ================= DASHBOARD CONTENT ================= */

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔴 COUNTS
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('sos_alerts').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              final activeCount = data
                  .where((a) => a['status'] != 'completed')
                  .length;

              final resolvedCount = data
                  .where((a) => a['status'] == 'completed')
                  .length;

              final deployedCount = data
                  .where((a) => a['status'] == 'assigned')
                  .length;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    title: 'Active Alerts',
                    value: activeCount.toString(),
                    color: Colors.redAccent,
                  ),
                  _StatCard(
                    title: 'Resolved',
                    value: resolvedCount.toString(),
                    color: Colors.greenAccent,
                  ),
                  _StatCard(
                    title: 'Teams Deployed',
                    value: deployedCount.toString(),
                    color: Colors.blueAccent,
                  ),
                  // const _StatCard(
                  //   title: 'Avg Response',
                  //   value: '-',
                  //   color: Colors.orangeAccent,
                  // ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Critical Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// 🔴 ACTIVE ALERT LIST
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('sos_alerts')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final activeAlerts = snapshot.data!
                  .where((a) => a['status'] != 'completed')
                  .toList();

              if (activeAlerts.isEmpty) {
                return const Text(
                  'No Active Alerts',
                  style: TextStyle(
                    color: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                );
              }

              return Column(
                children: activeAlerts.map((alert) {
                  return _alertCard(
                    alert['type'] ?? 'Unknown',
                    'Lat: ${alert['latitude']} , Lng: ${alert['longitude']}',
                    _timeAgo(DateTime.parse(alert['created_at'])),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ================= UI HELPERS ================= */

Widget _alertCard(String type, String location, String timeAgo) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$location\n$timeAgo'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('HIGH'),
      ),
    ),
  );
}

/* ================= STAT CARD ================= */

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/* ================= TIME AGO ================= */

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} day ago';
}
