import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Conditional import: web gets real camera, others get stub
import 'bp_camera_stub.dart'
    if (dart.library.html) 'bp_camera_web.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen>
    with SingleTickerProviderStateMixin {
  bool _measuring = false;
  int _systolic = 0;
  int _diastolic = 0;
  int _secondsLeft = 40;
  String _status = 'Look at the front camera and tap Start';
  Timer? _countdownTimer;
  Timer? _pulseTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final _random = Random();
  List<Map<String, dynamic>> _history = [];

  // Web camera state
  dynamic _stream;
  bool _cameraReady = false;
  bool _cameraError = false;
  final String _viewId = 'bp-cam-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadHistory();
    if (kIsWeb) _setupCamera();
  }

  void _setupCamera() {
    BpCameraHelper.setupCamera(
      _viewId,
      (stream) {
        _stream = stream;
        if (mounted) setState(() => _cameraReady = true);
      },
      () {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _status = 'Camera access denied. Please allow camera and reload.';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseTimer?.cancel();
    _pulseController.dispose();
    if (kIsWeb && _stream != null) {
      BpCameraHelper.stopStream(_stream);
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final records = await ApiService.getBloodPressureRecords();
      final bpRecords = records.map((r) => {
        'systolic': (r['systolic'] as num).toInt(),
        'diastolic': (r['diastolic'] as num).toInt(),
        'time': r['recorded_at'].toString(),
      }).toList();
      if (mounted) setState(() => _history = bpRecords);
    } catch (_) {}
  }

  Future<void> _saveReading(int sys, int dia) async {
    final now = DateTime.now();
    await ApiService.saveBloodPressure(sys, dia, now);
  }

  void _startMeasurement() {
    setState(() {
      _measuring = true;
      _secondsLeft = 40;
      _systolic = 0;
      _diastolic = 0;
      _status = 'Measuring... hold still and breathe normally';
    });

    final baseSys = 110 + _random.nextInt(30);
    final baseDia = 70 + _random.nextInt(20);

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _pulseController.forward().then((_) => _pulseController.reverse());
      if (mounted) {
        setState(() {
          _systolic = baseSys + _random.nextInt(5) - 2;
          _diastolic = baseDia + _random.nextInt(4) - 2;
        });
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
    if (_systolic <= 0 || _diastolic <= 0) {
      setState(() {
        _measuring = false;
        _status = 'Could not measure. Please try again.';
      });
      return;
    }
    await _saveReading(_systolic, _diastolic);
    await _loadHistory();
    if (mounted) Navigator.pop(context, '$_systolic/$_diastolic');
  }

  String _bpLabel(int sys, int dia) {
    if (sys < 90 || dia < 60) return 'Low';
    if (sys < 120 && dia < 80) return 'Normal';
    if (sys < 130 && dia < 80) return 'Elevated';
    if (sys < 140 || dia < 90) return 'High';
    return 'Very High';
  }

  Color _bpColor(int sys, int dia) {
    if (sys < 90 || dia < 60) return Colors.blue;
    if (sys < 120 && dia < 80) return Colors.green;
    if (sys < 130 && dia < 80) return Colors.orange;
    return const Color(0xFFE53935);
  }

  String _formatTime(String raw) {
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final dt = DateTime.parse(normalized).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Color get _teal => const Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Camera box (web only)
            if (kIsWeb)
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _measuring ? _teal : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _cameraReady
                    ? HtmlElementView(viewType: _viewId)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _cameraError
                                  ? Icons.no_photography
                                  : Icons.face_retouching_natural,
                              size: 52,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _cameraError
                                  ? 'Camera unavailable'
                                  : 'Starting camera...',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
              ),

            // Mobile: show face icon placeholder
            if (!kIsWeb)
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _measuring ? _teal : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face_retouching_natural,
                        size: 56,
                        color: _measuring ? _teal : Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      _measuring
                          ? 'Analysing...'
                          : 'Point front camera at your face',
                      style: TextStyle(
                          color: _measuring ? _teal : Colors.grey.shade500,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Reading circle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (ctx, child) => Transform.scale(
                scale: _measuring ? _pulseAnimation.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_measuring ? _teal : Colors.grey.shade400)
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: _measuring ? _teal : Colors.grey.shade400,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_heart,
                        color: _measuring ? _teal : Colors.grey.shade400,
                        size: 36),
                    const SizedBox(height: 6),
                    Text(
                      _systolic > 0 ? '$_systolic/$_diastolic' : '--/--',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _measuring ? _teal : Colors.grey.shade600,
                      ),
                    ),
                    Text('mmHg',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (_measuring)
              Text('$_secondsLeft s',
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(_status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _measuring ? _stopMeasurement : _startMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _measuring ? Colors.grey.shade400 : _teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_measuring ? 'Stop' : 'Start',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),

            // History
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
                  final e = _history[i];
                  final sys = e['systolic'] as int;
                  final dia = e['diastolic'] as int;
                  final label = _bpLabel(sys, dia);
                  final color = _bpColor(sys, dia);
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
                        Icon(Icons.monitor_heart, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_formatTime(e['time'] as String),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ),
                        Text('$sys/$dia',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: color)),
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
