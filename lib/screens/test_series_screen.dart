import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_engine_screen.dart';

class TestSeriesScreen extends StatelessWidget {
  const TestSeriesScreen({super.key});

  final List<Map<String, dynamic>> testPacks = const [
    {
      'title': 'UP Police Constable 2026 Full Test Series',
      'tests': '25 Full Tests + 50 Sectional',
      'price': 149,
      'isPaid': true,
      'badge': 'PAID PASS',
    },
    {
      'title': 'SSC CGL Tier-1 All India Free Mock Test',
      'tests': '1 Free Demo Test Available',
      'price': 0,
      'isPaid': false,
      'badge': 'FREE MOCK',
    },
    {
      'title': 'RRB NTPC & Group D Special Test Pass',
      'tests': '30 Full Tests',
      'price': 199,
      'isPaid': true,
      'badge': 'PAID PASS',
    },
  ];

  void _processPayment(BuildContext context, String title, int price) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.payment, size: 48, color: Color(0xFF1A237E)),
              const SizedBox(height: 12),
              Text(
                'Checkout - CompeteMe Pass',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount Payable: ₹$price',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Payment Successful for $title! Pass Activated."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'PAY VIA RAZORPAY / UPI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series & Mocks'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: testPacks.length,
        itemBuilder: (context, index) {
          final pack = testPacks[index];
          final isPaid = pack['isPaid'] as bool;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pack['badge'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                      Text(
                        isPaid ? '₹${pack['price']}' : 'FREE',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? const Color(0xFF1A237E)
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pack['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack['tests'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (isPaid) {
                          _processPayment(
                            context,
                            pack['title'],
                            pack['price'],
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizEngineScreen(),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isPaid ? Icons.lock_open : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        isPaid
                            ? 'BUY TEST SERIES (₹${pack['price']})'
                            : 'START FREE MOCK TEST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
