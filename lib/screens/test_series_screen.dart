import 'package:flutter/material.dart';
import 'quiz_engine_screen.dart';

class TestSeriesScreen extends StatelessWidget {
  const TestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series & Mocks'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTestCard(
            context,
            title: 'UP Police Constable 2026 Full Test Series',
            totalTests: '25 Full Tests + 50 Sectional',
            price: '₹149',
            isPaid: true,
          ),
          const SizedBox(height: 14),
          _buildTestCard(
            context,
            title: 'SSC CGL Tier-1 All India Free Mock Test',
            totalTests: '1 Free Demo Test Available',
            price: 'FREE',
            isPaid: false,
          ),
          const SizedBox(height: 14),
          _buildTestCard(
            context,
            title: 'RRB NTPC & Group D Special Test Pass',
            totalTests: '30 Full Tests',
            price: '₹199',
            isPaid: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String totalTests,
    required String price,
    required bool isPaid,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    isPaid ? 'PAID PASS' : 'FREE MOCK',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isPaid ? Colors.orange.shade800 : Colors.green.shade700,
                ),
                Text(
                  price,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              totalTests,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(isPaid ? Icons.lock_open : Icons.play_arrow, color: Colors.white),
                label: Text(
                  isPaid ? 'BUY TEST SERIES ($price)' : 'START FREE MOCK TEST',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (isPaid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Razorpay Payment Checkout...')),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizEngineScreen()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
