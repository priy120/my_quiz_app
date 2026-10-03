import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/group_service.dart';
import '../utils/poster_helper.dart';

class GroupStudyScreen extends StatefulWidget {
  const GroupStudyScreen({Key? key}) : super(key: key);

  static String? activeGroupCode;

  @override
  State<GroupStudyScreen> createState() => _GroupStudyScreenState();
}

class _GroupStudyScreenState extends State<GroupStudyScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _posterKey = GlobalKey();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Study Circle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: "Enter Group/Library Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                String? code = await _groupService.createGroup(_nameController.text);
                Navigator.pop(context);
                if (code != null) {
                  setState(() => GroupStudyScreen.activeGroupCode = code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Group Created! Code: $code")),
                  );
                }
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Join Study Circle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            hintText: "Enter 6-Digit Code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              if (_codeController.text.isNotEmpty) {
                bool success = await _groupService.joinGroup(_codeController.text);
                Navigator.pop(context);
                if (success) {
                  setState(() => GroupStudyScreen.activeGroupCode = _codeController.text.toUpperCase());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid Group Code!")),
                  );
                }
              }
            },
            child: const Text("Join", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Study Group Portal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: GroupStudyScreen.activeGroupCode != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.leaderboard), text: "Leaderboard"),
                  Tab(icon: Icon(Icons.help_center), text: "Doubt Wall"),
                ],
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: GroupStudyScreen.activeGroupCode == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_rounded, size: 80, color: Color(0xFF1A237E)),
                    const SizedBox(height: 16),
                    Text(
                      "Compete with Library Friends!",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create or join a study group to sync mock scores live.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text("Create New Group", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _showCreateGroupDialog,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.login, color: Color(0xFF1A237E)),
                        label: Text("Join Group with Code", style: GoogleFonts.poppins(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1A237E)),
                        ),
                        onPressed: _showJoinGroupDialog,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _groupService.getGroupDetails(GroupStudyScreen.activeGroupCode!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var groupData = snapshot.data!.data() as Map<String, dynamic>?;
                if (groupData == null) return const Center(child: Text("Group Data Not Found"));

                Map<String, dynamic> membersMap = groupData['memberDetails'] ?? {};
                List memberList = membersMap.values.toList();
                memberList.sort((a, b) => (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0));

                String topScorer = memberList.isNotEmpty ? (memberList[0]['name'] ?? 'Topper') : 'N/A';
                dynamic topScore = memberList.isNotEmpty ? (memberList[0]['totalScore'] ?? 0) : 0;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: LEADERBOARD + POSTER
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: _posterKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("CompeteMe Study Group", style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                        child: Text("CODE: ${groupData['groupCode']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    groupData['groupName'] ?? "Study Group",
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("👑 Current Leader: $topScorer ($topScore pts)", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                                      icon: const Icon(Icons.share, color: Colors.white, size: 16),
                                      label: Text("Share Challenge Poster", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      onPressed: () {
                                        PosterHelper.shareGroupPoster(
                                          _posterKey,
                                          groupData['groupCode'],
                                          groupData['groupName'],
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("🏆 LIVE LEADERBOARD", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                Text("${memberList.length} Members", style: GoogleFonts.poppins(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: memberList.length,
                            itemBuilder: (context, index) {
                              var member = memberList[index];
                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey.shade400 : (index == 2 ? Colors.brown.shade300 : Colors.indigo.shade50)),
                                    child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.black : Colors.indigo)),
                                  ),
                                  title: Text(member['name'] ?? "Student", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Text("Tests Given: ${member['testsGiven'] ?? 0}", style: const TextStyle(fontSize: 11)),
                                  trailing: Text(
                                    "${member['totalScore'] ?? 0} pts",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // TAB 2: GROUP DOUBT WALL
                    StreamBuilder<QuerySnapshot>(
                      stream: _groupService.getGroupDoubts(GroupStudyScreen.activeGroupCode!),
                      builder: (context, doubtSnap) {
                        if (!doubtSnap.hasData) return const Center(child: CircularProgressIndicator());
                        var doubts = doubtSnap.data!.docs;

                        if (doubts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mark_chat_read_outlined, size: 60, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text("No doubts asked in this group yet!", style: GoogleFonts.poppins(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: doubts.length,
                          itemBuilder: (context, index) {
                            var doubt = doubts[index].data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(doubt['askedBy'] ?? "Student", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), fontSize: 12)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: Text(doubt['testTitle'] ?? "Mock Test", style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 12),
                                    Text(doubt['questionText'] ?? "", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
