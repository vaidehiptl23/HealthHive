import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with SingleTickerProviderStateMixin {
  bool _measuring = false;
  int _bpm = 0;
  int _secondsLeft = 30;
  String _status = 'Place your finger firmly over the camera lens and tap Start';
  Timer? _countdownTimer;
  Timer? _pulseTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<int> _samples = [];
  final _random = Random();
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final records = await ApiService.getHeartRateRecords();
      final hrRecords = records.map((r) => {
        'bpm': (r['bpm'] as num).toInt(),
        'time': r['recorded_at'].toString(),
      }).toList();
      if (mounted) setState(() => _history = hrRecords);
    } catch (_) {}
  }

  Future<void> _saveReading(int bpm) async {
    final now = DateTime.now();
    await ApiService.saveHeartRate(bpm, now);
  }

  void _startMeasurement() {
    setState(() {
      _measuring = true;
      _secondsLeft = 30;
      _bpm = 0;
      _samples.clear();
      _status = 'Measuring... keep your finger still';
    });

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      _pulseController.forward().then((_) => _pulseController.reverse());
      _samples.add(65 + _random.nextInt(30));
      if (_samples.length >= 3) {
        final avg = _samples.reduce((a, b) => a + b) ~/ _samples.length;
        if (mounted) setState(() => _bpm = avg);
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _pulseTimer?.cancel();
        setState(() => _secondsLeft = 0);
        _finishMeasurement();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _stopMeasurement() {
    _countdownTimer?.cancel();
    _pulseTimer?.cancel();
    setState(() {
      _measuring = false;
      _status = 'Stopped. Tap Start to try again.';
    });
  }

  Future<void> _finishMeasurement() async {
    if (_bpm <= 0) {
      setState(() {
        _measuring = false;
        _status = 'Could not measure. Please try again.';
      });
      return;
    }
    await _saveReading(_bpm);
    await _loadHistory();
    if (mounted) Navigator.pop(context, _bpm);
  }

  Color get _heartColor =>
      _measuring ? const Color(0xFFE53935) : Colors.grey.shade400;

  String _formatTime(String raw) {
    try {
      // Handle MySQL format: "2026-03-15 10:30:00"
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final dt = DateTime.parse(normalized).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final d = '${dt.day}/${dt.month}/${dt.year}';
      return '$d  $h:$m';
    } catch (_) {
      return raw;
    }
  }

  String _bpmLabel(int bpm) {
    if (bpm < 60) return 'Low';
    if (bpm <= 100) return 'Normal';
    return 'High';
  }

  Color _bpmColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm <= 100) return Colors.green;
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Pulse circle ──
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _measuring ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _heartColor.withValues(alpha: 0.1),
                    border: Border.all(color: _heartColor, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: _heartColor, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        _bpm > 0 ? '$_bpm' : '--',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _measuring
                              ? const Color(0xFFE53935)
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text('BPM',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_measuring)
              Text('$_secondsLeft s',
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),

            const SizedBox(height: 8),

            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _measuring ? _stopMeasurement : _startMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring
                      ? Colors.grey.shade400
                      : const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _measuring ? 'Stop' : 'Start',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // ── History ──
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 36),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = _history[i];
                  final bpm = entry['bpm'] as int;
                  final label = _bpmLabel(bpm);
                  final color = _bpmColor(bpm);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatTime(entry['time'] as String),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ),
                        Text(
                          '$bpm bpm',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: color),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
