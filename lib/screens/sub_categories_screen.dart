import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'test_series_screen.dart';

class SubCategoriesScreen extends StatefulWidget {
  final String categoryName;

  const SubCategoriesScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  late Razorpay _razorpay;

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

  void _startRazorpayPayment() {
    var options = {
      'key': 'rzp_live_TcFnwjnPCAzll2',
      'amount': 29900, // ₹299.00 in paise
      'name': 'CompeteMe Portal',
      'description': '${widget.categoryName} Test Series Pass',
      'prefill': {
        'contact': '9999999999',
        'email': 'priyanshu2001pal@gmail.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful! ID: ${response.paymentId}'), backgroundColor: Colors.green),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet Selected: ${response.walletName}'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          '${widget.categoryName} Packages',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mock_tests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;

          final categoryDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docCat = (data['category'] ?? '').toString().toUpperCase();
            return docCat == widget.categoryName.toUpperCase();
          }).toList();

          final Map<String, Map<String, int>> subCategoryMap = {};

          for (var doc in categoryDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final subCat = (data['subCategory'] ?? 'General Mock Tests').toString();
            final bool isFree = data['isFree'] ?? false;

            if (!subCategoryMap.containsKey(subCat)) {
              subCategoryMap[subCat] = {'total': 0, 'free': 0};
            }

            subCategoryMap[subCat]!['total'] = (subCategoryMap[subCat]!['total'] ?? 0) + 1;
            if (isFree) {
              subCategoryMap[subCat]!['free'] = (subCategoryMap[subCat]!['free'] ?? 0) + 1;
            }
          }

          if (subCategoryMap.isEmpty) {
            return Center(
              child: Text(
                'No packages available for ${widget.categoryName} yet.',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            );
          }

          final subCatList = subCategoryMap.keys.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: subCatList.length,
                  itemBuilder: (context, index) {
                    final subCatTitle = subCatList[index];
                    final totalTests = subCategoryMap[subCatTitle]!['total'] ?? 0;
                    final freeTests = subCategoryMap[subCatTitle]!['free'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/d/d4/Staff_Selection_Commission_Logo.png',
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.indigo, size: 28),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    subCatTitle,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('$totalTests Total tests', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 8),
                                const Text('|', style: TextStyle(color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text('$freeTests Free Test', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TestSeriesScreen(
                                          categoryName: widget.categoryName,
                                          subCategoryName: subCatTitle,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('View Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.lock, color: Colors.red, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1A237E),
                child: SafeArea(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _startRazorpayPayment,
                    child: const Text('Buy Now', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
