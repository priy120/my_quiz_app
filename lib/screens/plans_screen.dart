import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late Razorpay _razorpay;
  final TextEditingController _couponController = TextEditingController();
  
  int _selectedPlanPrice = 199; // Default selected plan price ₹199
  String _selectedPlanTitle = 'CompeteMe 1 Year All Pass';
  bool _isCouponApplied = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'COMPETE50' || code == 'FIRST100') {
      setState(() {
        _isCouponApplied = true;
        _selectedPlanPrice = (_selectedPlanPrice - 50).clamp(0, 9999);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Coupon Applied! ₹50 Discount Added.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Coupon Code'), backgroundColor: Colors.red),
      );
    }
  }

  void _openRazorpay() {
    var options = {
      'key': 'rzp_live_TcFnwjnPCAzll2',
      'amount': _selectedPlanPrice * 100, // Convert ₹ to Paise
      'name': 'CompeteMe Portal',
      'description': _selectedPlanTitle,
      'prefill': {'contact': '9999999999', 'email': 'priyanshu2001pal@gmail.com'}
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Gateway Error: $e')));
    }
  }

  void _handleSuccess(PaymentSuccessResponse r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful! Pass ID: ${r.paymentId}'), backgroundColor: Colors.green),
    );
    Navigator.pop(context); // Return to previous screen
  }

  void _handleError(PaymentFailureResponse r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${r.message}'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('CompeteMe Test Pass', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CompeteMe Premium Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text('CompeteMe Unlimited Pass 🎯', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Unlock SSC, Railways, Banking & Police Mock Series with Detailed Solutions & Analysis.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Select Subscription Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            // Plan Option 1: 1 Year Pass
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _selectedPlanPrice == (_isCouponApplied ? 149 : 199) ? const Color(0xFF1A237E) : Colors.grey.shade300, width: 2),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedPlanPrice = _isCouponApplied ? 149 : 199;
                    _selectedPlanTitle = 'CompeteMe 1 Year All Pass';
                  });
                },
                leading: Radio<int>(
                  value: _isCouponApplied ? 149 : 199,
                  groupValue: _selectedPlanPrice,
                  activeColor: const Color(0xFF1A237E),
                  onChanged: (val) {
                    setState(() {
                      _selectedPlanPrice = val!;
                      _selectedPlanTitle = 'CompeteMe 1 Year All Pass';
                    });
                  },
                ),
                title: Text('1 Year All Exam Pass', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Access 500+ Full & Sectional Mock Tests'),
                trailing: Text('₹${_isCouponApplied ? 149 : 199}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A237E))),
              ),
            ),

            const SizedBox(height: 20),
            Text('Pass Features & Benefits', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            _buildFeatureRow('100% Eduquity & TCS Standard Mock Test Papers'),
            _buildFeatureRow('Bilingual Support (Hindi + English) with Instant Switch'),
            _buildFeatureRow('Detailed Solutions & Sectional Performance Analysis'),
            _buildFeatureRow('Unlimited Re-attempts for all exams'),

            const SizedBox(height: 24),
            Text('Apply Discount Coupon', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: 'Enter code (e.g. COMPETE50)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: _applyCoupon,
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Pay Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openRazorpay,
                child: Text('Pay ₹$_selectedPlanPrice & Unlock Pass', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
