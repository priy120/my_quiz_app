import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/group_service.dart';

class GroupStudyScreen extends StatefulWidget {
  const GroupStudyScreen({Key? key}) : super(key: key);

  @override
  State<GroupStudyScreen> createState() => _GroupStudyScreenState();
}

class _GroupStudyScreenState extends State<GroupStudyScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? currentGroupCode;

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Library / Study Group"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: "Enter Group Name (e.g. Focus Library)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                String? code = await _groupService.createGroup(_nameController.text);
                Navigator.pop(context);
                if (code != null) {
                  setState(() {
                    currentGroupCode = code;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Group Created! Code: $code")),
                  );
                }
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Study Group"),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            hintText: "Enter 6-Digit Group Code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_codeController.text.isNotEmpty) {
                bool success = await _groupService.joinGroup(_codeController.text);
                Navigator.pop(context);
                if (success) {
                  setState(() {
                    currentGroupCode = _codeController.text.toUpperCase();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid Group Code!")),
                  );
                }
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Group / Library"),
        centerTitle: true,
      ),
      body: currentGroupCode == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_rounded, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    "Compete with Library Friends!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Create New Group"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _showCreateGroupDialog,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Join Group with Code"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _showJoinGroupDialog,
                  ),
                ],
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _groupService.getGroupDetails(currentGroupCode!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var groupData = snapshot.data!.data() as Map<String, dynamic>?;
                if (groupData == null) return const Text("Group Data Not Found");

                Map<String, dynamic> membersMap = groupData['memberDetails'] ?? {};
                List memberList = membersMap.values.toList();

                memberList.sort((a, b) => (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0));

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupData['groupName'] ?? "Study Group",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text("Group Code: ${groupData['groupCode']}"),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Code copied!")),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "🏆 Group Leaderboard",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: memberList.length,
                        itemBuilder: (context, index) {
                          var member = memberList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text("${index + 1}"),
                            ),
                            title: Text(member['name'] ?? "Student"),
                            subtitle: Text("Tests Given: ${member['testsGiven'] ?? 0}"),
                            trailing: Text(
                              "${member['totalScore'] ?? 0} pts",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.green),
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
