import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    // Interstitial/Rewarded Ad pre-load for fast response on tap
    UnityAds.load(
      placementId: 'BP_Interstitial_Android',
      onComplete: (placementId) => debugPrint('PDF Ad Loaded: $placementId'),
      onFailed: (placementId, error, message) =>
          debugPrint('PDF Ad Load Failed: $message'),
    );
  }

  Future<void> _openPdfWithAd(BuildContext context, String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF link is invalid or empty.")),
      );
      return;
    }

    setState(() => _isAdLoading = true);

    // Show Interstitial Ad before launching PDF
    UnityAds.showVideoAd(
      placementId: 'BP_Interstitial_Android',
      onComplete: (placementId) async {
        setState(() => _isAdLoading = false);
        _launchPdfUrl(context, urlString);
      },
      onFailed: (placementId, error, message) async {
        setState(() => _isAdLoading = false);
        // Fallback: If ad fails, still open PDF so user experience doesn't break
        _launchPdfUrl(context, urlString);
      },
      onSkipped: (placementId) async {
        setState(() => _isAdLoading = false);
        _launchPdfUrl(context, urlString);
      },
    );
  }

  Future<void> _launchPdfUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open PDF link.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening PDF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("Abhi koi PDF Notes upload nahi hain. Admin Panel se add karein."),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Study Material';
                        final category = data['category'] ?? 'Notes';
                        final size = data['size'] ?? '2.0 MB';
                        final date = data['date'] ?? '2026';
                        final pdfUrl = data['url'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF1A237E),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$size • $date',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye,
                                      color: Color(0xFF1A237E)),
                                  onPressed: () => _openPdfWithAd(context, pdfUrl),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Bottom Persistent Banner Ad
              Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: UnityBannerAd(
                  placementId: 'BP_Banner_Android',
                  onLoad: (placementId) => debugPrint('PDF Banner Loaded: $placementId'),
                  onFailed: (placementId, error, message) =>
                      debugPrint('PDF Banner Failed: $message'),
                ),
              ),
            ],
          ),
          if (_isAdLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Opening PDF Note...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
