import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'instructions_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  final String razorpayKey = "rzp_live_TcFnwjnPCAzll2";
  final int passPrice = 149;

  late TabController _tabController;
  String _selectedSubCategory = 'SSC CGL'; // Default Sub Exam
  String _activeFilter = 'All'; // Sub Filter

  final List<String> _subCategories = [
    'SSC CGL',
    'SSC CPO',
    'SSC CHSL',
    'SSC MTS',
    'SSC GD',
    'Railways',
    'UP Police',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _buyCompeteMePass() {
    final user = FirebaseAuth.instance.currentUser;
    var options = {
      'key': razorpayKey,
      'amount': passPrice * 100,
      'name': 'CompeteMe Yearly Pass',
      'description': '1 Year Unlimited Access to All Test Series',
      'prefill': {
        'contact': user?.phoneNumber ?? '7678898727',
        'email': user?.email ?? 'priyanshu2001pal@gmail.com'
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'hasActivePass': true,
        'passActivatedAt': FieldValue.serverTimestamp(),
        'paymentId': response.paymentId,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CompeteMe Pass Activated! All Tests Unlocked 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Text(
          'CompeteMe Test Portal',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final bool hasPass = userData['hasActivePass'] ?? false;

                return Column(
                  children: [
                    // Pass Banner Top Bar
                    _buildPassBanner(hasPass),

                    // Exam Sub-Categories Horizontal Selector Bar
                    Container(
                      height: 48,
                      color: Colors.white,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final cat = _subCategories[index];
                          final isSelected = cat == _selectedSubCategory;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: const Color(0xFF1A237E),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (val) {
                                setState(() => _selectedSubCategory = cat);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Main Multi-Tab Header (Full Mocks, PYQs, Sectionals)
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1A237E),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF1A237E),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Full Mocks'),
                          Tab(text: 'Previous Years'),
                          Tab(text: 'Sectional Tests'),
                        ],
                      ),
                    ),

                    // Sub Filter Chips Bar (All, Free, Latest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: ['All', 'Free Demo', 'Latest'].map((filter) {
                          final isSelected = _activeFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              onSelected: (val) {
                                setState(() => _activeFilter = filter);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Test List View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTestList('Full Mock', hasPass),
                          _buildTestList('PYQ', hasPass),
                          _buildTestList('Sectional', hasPass),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPassBanner(bool hasPass) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasPass ? [Colors.green.shade800, Colors.green.shade600] : [const Color(0xFF1A237E), Colors.indigo.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPass ? 'COMPETEME PASS ACTIVE 🎉' : 'COMPETEME YEARLY PASS',
                  style: GoogleFonts.poppins(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  hasPass ? 'Unlimited Access Unlocked for 1 Year' : 'Unlock All 100+ Mock Tests & PYQs @ ₹$passPrice',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!hasPass)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: _buyCompeteMePass,
              child: const Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildTestList(String testTypeTag, bool hasPass) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data?.docs ?? [];

        // Filter tests by selected sub-category
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = (data['category'] ?? '').toString().toLowerCase();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final isFree = data['isFree'] ?? false;

          bool matchesCategory = category.contains(_selectedSubCategory.toLowerCase()) || title.contains(_selectedSubCategory.toLowerCase());

          if (_activeFilter == 'Free Demo') {
            return matchesCategory && isFree;
          }
          return matchesCategory;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No $testTypeTag tests available for $_selectedSubCategory yet',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final test = doc.data() as Map<String, dynamic>;
            final testId = doc.id;
            final title = test['title'] ?? 'Mock Test';
            final durationMinutes = test['durationMinutes'] ?? 60;
            final totalMarks = test['totalMarks'] ?? 200;
            final isFree = test['isFree'] ?? false;
            final bool canAttempt = isFree || hasPass;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 1.5,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                title: Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$durationMinutes Mins  •  ', style: const TextStyle(fontSize: 11)),
                      const Icon(Icons.assignment_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$totalMarks Marks', style: const TextStyle(fontSize: 11)),
                      if (isFree)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                          child: const Text('FREE DEMO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                        ),
                    ],
                  ),
                ),
                trailing: canAttempt
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          // Redirect to Instructions Screen First
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InstructionsScreen(
                                testId: testId,
                                testTitle: title,
                                durationMinutes: durationMinutes,
                                totalMarks: totalMarks,
                              ),
                            ),
                          );
                        },
                        child: const Text('START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _buyCompeteMePass,
                        icon: const Icon(Icons.lock, size: 14, color: Colors.redAccent),
                        label: const Text('UNLOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
