import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'quiz_engine_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  late Razorpay _razorpay;
  final String razorpayKey = "rzp_live_TcFnwjnPCAzll2";
  final int passPrice = 149; // CompeteMe Yearly Pass Price

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _buyCompeteMePass() {
    final user = FirebaseAuth.instance.currentUser;
    var options = {
      'key': razorpayKey,
      'amount': passPrice * 100, // Amount in Paise
      'name': 'CompeteMe Pass',
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
      // User Document me Pass Active Mark Karo
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
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
          'CompeteMe Test Pass',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final bool hasPass = userData['hasActivePass'] ?? false;

                return Column(
                  children: [
                    // Testbook Style Pass Card Top Banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasPass
                              ? [Colors.green.shade800, Colors.green.shade600]
                              : [const Color(0xFF1A237E), Colors.indigo.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPass ? 'PASS ACTIVE 🎉' : 'COMPETEME PASS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasPass
                                      ? 'You have unlimited access to all tests!'
                                      : 'Unlock All 100+ Mock Tests for 1 Year',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!hasPass)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: _buyCompeteMePass,
                              child: Text(
                                'BUY @ ₹$passPrice',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Live Test Series List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('mock_tests')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                'No Test Series Available Yet',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final pack = doc.data() as Map<String, dynamic>;
                              final testId = doc.id;
                              final title = pack['title'] ?? 'Mock Test';
                              final category =
                                  pack['category'] ?? 'General Exam';
                              final durationMinutes =
                                  pack['durationMinutes'] ?? 60;
                              final isFree = pack['isFree'] ?? false;

                              final bool canAttempt = isFree || hasPass;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  subtitle: Text(
                                      '$category • $durationMinutes Mins'),
                                  trailing: canAttempt
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1A237E),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuizEngineScreen(
                                                  testId: testId,
                                                  testTitle: title,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('START',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        )
                                      : ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade400,
                                          ),
                                          onPressed: _buyCompeteMePass,
                                          icon: const Icon(Icons.lock,
                                              size: 16, color: Colors.black87),
                                          label: const Text('UNLOCK',
                                              style: TextStyle(
                                                  color: Colors.black87)),
                                        ),
                                ),
                              );
                            },
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
