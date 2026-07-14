import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav.dart';

class RecentlyTrackedScreen extends StatefulWidget {
  final String userEmail;
  const RecentlyTrackedScreen({super.key, required this.userEmail});

  @override
  State<RecentlyTrackedScreen> createState() => _RecentlyTrackedScreenState();
}

class _RecentlyTrackedScreenState extends State<RecentlyTrackedScreen> {
  List<Map<String, dynamic>> _combined = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final hrRecords = await ApiService.getHeartRateRecords();
    final bpRecords = await ApiService.getBloodPressureRecords();
    final List<Map<String, dynamic>> all = [];
    for (final r in hrRecords) {
      final time = r['recorded_at'].toString().replaceFirst(' ', 'T');
      all.add({'type': 'Heart Rate', 'value': '${r['bpm']} bpm', 'time': time});
    }
    for (final r in bpRecords) {
      final time = r['recorded_at'].toString().replaceFirst(' ', 'T');
      all.add({'type': 'Blood Pressure', 'value': '${r['systolic']}/${r['diastolic']} mmHg', 'time': time});
    }
    all.sort((a, b) =>
        DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])));
    if (mounted) setState(() { _combined = all; _loading = false; });
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  void _showVitalsTrendAnalysis() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Analyzing Vitals with AI...", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    final res = await ApiService.getVitalsTrends();
    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true && res['trends'] != null) {
      _showReportSheet(res['trends']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to analyze vitals trends'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReportSheet(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text("AI Vitals Trend Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...content.split('\n').map((line) {
                      final trimmed = line.trim();
                      if (trimmed.startsWith('###')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            trimmed.replaceAll('###', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('##')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            trimmed.replaceAll('##', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('#')) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Text(
                            trimmed.replaceAll('#', '').trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        );
                      } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                              Expanded(
                                child: Text(
                                  trimmed.substring(1).trim().replaceAll('**', ''),
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (trimmed.isEmpty) {
                        return const SizedBox(height: 10);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          trimmed.replaceAll('**', ''),
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar:
          CustomBottomNav(currentIndex: 0, userEmail: widget.userEmail),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6)
                        ],
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Recently Tracked',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (_combined.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      tooltip: "AI Trend Analysis",
                      onPressed: _showVitalsTrendAnalysis,
                    ),
                ],
              ),

              const SizedBox(height: 24),

              if (_loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (_combined.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No readings yet',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Measure your HR or BP from the home screen',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _combined.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = _combined[i];
                      final isHR = item['type'] == 'Heart Rate';
                      const softRed = Color(0xFFB71C1C);
                      const deepTeal = Color(0xFF00695C);
                      final color = isHR ? softRed : deepTeal;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isHR ? Icons.favorite : Icons.monitor_heart,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['type'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(item['value'],
                                      style: TextStyle(
                                          fontSize: 14, color: color,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(_formatTime(item['time']),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
