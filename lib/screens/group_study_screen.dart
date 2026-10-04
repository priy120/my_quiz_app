import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _replyController = TextEditingController();
  final GlobalKey _posterKey = GlobalKey();
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedGroupCode();
  }

  Future<void> _loadSavedGroupCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCode = prefs.getString('user_group_code');
    if (savedCode != null && savedCode.isNotEmpty) {
      GroupStudyScreen.activeGroupCode = savedCode;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveGroupCodeLocally(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_group_code', code);
    if (mounted) setState(() => GroupStudyScreen.activeGroupCode = code);
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Study Circle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: "Enter Group/Library Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                String? code = await _groupService.createGroup(_nameController.text);
                Navigator.pop(context);
                if (code != null) await _saveGroupCodeLocally(code);
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
          decoration: const InputDecoration(hintText: "Enter 6-Digit Code", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              if (_codeController.text.isNotEmpty) {
                String cleanCode = _codeController.text.trim().toUpperCase();
                bool success = await _groupService.joinGroup(cleanCode);
                Navigator.pop(context);
                if (success) await _saveGroupCodeLocally(cleanCode);
              }
            },
            child: const Text("Join", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String doubtId) {
    _replyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Answer this Doubt", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        content: TextField(
          controller: _replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Write solution or explanation...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () async {
              if (_replyController.text.trim().isNotEmpty) {
                await _groupService.addDoubtAnswer(
                  groupCode: GroupStudyScreen.activeGroupCode!,
                  doubtId: doubtId,
                  replyText: _replyController.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Post Answer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Study Group Portal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (GroupStudyScreen.activeGroupCode != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              tooltip: "Leave Group",
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_group_code');
                setState(() => GroupStudyScreen.activeGroupCode = null);
              },
            )
        ],
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
                    Text("Compete with Library Friends!", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text("Create New Group", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _showCreateGroupDialog,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.login, color: Color(0xFF1A237E)),
                        label: Text("Join Group with Code", style: GoogleFonts.poppins(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
                    // TAB 1: LEADERBOARD
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

                    // TAB 2: INTERACTIVE DOUBT WALL
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
                            var doc = doubts[index];
                            var doubt = doc.data() as Map<String, dynamic>;
                            List answers = doubt['answers'] ?? [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          doubt['askedBy'] ?? "Student",
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: Text(
                                            doubt['testTitle'] ?? "Mock Test",
                                            style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF1A237E), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 14),
                                    Text(doubt['questionText'] ?? "", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                                    
                                    // ANSWERS FEED
                                    if (answers.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("💡 Answers (${answers.length}):", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                            const SizedBox(height: 4),
                                            ...answers.map((ans) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 4.0),
                                                  child: Text(
                                                    "• ${ans['answeredBy']}: ${ans['answerText']}",
                                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                        icon: const Icon(Icons.reply, size: 14, color: Colors.orange),
                                        label: Text("Answer Doubt", style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                                        onPressed: () => _showReplyDialog(doc.id),
                                      ),
                                    )
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
