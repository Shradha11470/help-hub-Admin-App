import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iqwbgmlpkfaqytjqcphh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlxd2JnbWxwa2ZhcXl0anFjcGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTMwNzEsImV4cCI6MjA4MTE2OTA3MX0.HzwheFwYCrjUJ6KRQfAoMkrJU60GoMD2Y9uJZMX__nY',
  );

  runApp(const Teams());
}

class Teams extends StatelessWidget {
  const Teams({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminHomePage(),
    );
  }
}

/// ================= ADMIN HOME =================
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// TEAMS BUTTON
            SizedBox(
              width: double.infinity,
              height: screenWidth * 0.14,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamsPage()),
                  );
                },
                child: const Text(
                  " RESCUE TEAMS",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ADD TEAM BUTTON
            SizedBox(
              width: double.infinity,
              height: screenWidth * 0.14,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTeamPage()),
                  );

                  if (result == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamsPage()),
                    );
                  }
                },
                child: const Text(
                  "ADD TEAM",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ADD TEAM =================
class AddTeamPage extends StatefulWidget {
  const AddTeamPage({super.key});

  @override
  State<AddTeamPage> createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> selectedEmergencyTypes = [];
  final teamNameController = TextEditingController();
  final leaderNameController = TextEditingController();
  final leaderMobileController = TextEditingController();
  final addressController = TextEditingController();

  final List<String> emergencyTypes = [
    "Fire",
    "Accident",
    "Flood",
    "Violence",
    "Earthquake",
    "Medical",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Team")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Select Emergency Types",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: emergencyTypes.map((type) {
                  final isSelected = selectedEmergencyTypes.contains(type);
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.blue.shade700,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedEmergencyTypes.add(type);
                        } else {
                          selectedEmergencyTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: teamNameController,
                decoration: const InputDecoration(labelText: "Team Name"),
                validator: (v) => v!.isEmpty ? "Enter team name" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: leaderNameController,
                decoration: const InputDecoration(labelText: "Leader Name"),
                validator: (v) => v!.isEmpty ? "Enter leader name" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: leaderMobileController,
                decoration:
                    const InputDecoration(labelText: "Leader Mobile No"),
                validator: (v) => v!.isEmpty ? "Enter mobile number" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (v) => v!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (selectedEmergencyTypes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Select at least one emergency type")),
                    );
                    return;
                  }

                  try {
                    await Supabase.instance.client.from('teams').insert({
                      'emergency_type': selectedEmergencyTypes.join(','),
                      'team_name': teamNameController.text,
                      'leader_name': leaderNameController.text,
                      'leader_mobile': leaderMobileController.text,
                      'address': addressController.text,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Team added successfully")),
                    );

                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                child: const Text("SUBMIT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= TEAMS LIST =================
class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List teams = [];

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    final data =
        await Supabase.instance.client.from('teams').select().order('created_at');
    setState(() => teams = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" Rescue Teams")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];

            List<String> tags = [];
            if (team['emergency_type'] != null) {
              tags = team['emergency_type'].toString().split(',');
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFF1C1C1E),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0B1020),
                  child: const Icon(Icons.shield, color: Colors.blue),
                ),
                title: Text(
                  team['team_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['leader_name'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: tags
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                // trailing:
                    // const Icon(Icons.circle, color: Colors.green, size: 16),
                // onTap: () {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(
                //         content:
                //             Text("${team['team_name']} assigned successfully")),
                //   );
                // },
              ),
            );
          },
        ),
      ),
    );
  }
}
