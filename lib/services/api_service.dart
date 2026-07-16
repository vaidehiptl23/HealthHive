import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://10.109.94.21:5000/api';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── PROFILE ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/profile'), headers: await _headers());
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$_baseUrl/auth/profile'), headers: await _headers(), body: jsonEncode(data));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── EMERGENCY DETAILS ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEmergencyDetails() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/emergency'), headers: await _headers());
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateEmergencyDetails(Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$_baseUrl/auth/emergency'), headers: await _headers(), body: jsonEncode(data));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── FAMILY MEMBERS ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateFamilyEmergencyDetails(int familyId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$_baseUrl/family/$familyId/emergency'), headers: await _headers(), body: jsonEncode(data));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/notifications'), headers: await _headers());
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    try {
      final res = await http.put(Uri.parse('$_baseUrl/notifications/$id/read'), headers: await _headers());
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── HEALTH RECORDS ────────────────────────────────────────────────────────

  // MySQL datetime format: 'YYYY-MM-DD HH:MM:SS'
  static String _toMysqlDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2,'0')}-${utc.day.toString().padLeft(2,'0')} '
        '${utc.hour.toString().padLeft(2,'0')}:${utc.minute.toString().padLeft(2,'0')}:${utc.second.toString().padLeft(2,'0')}';
  }

  static Future<bool> saveHeartRate(int bpm, DateTime time) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/heart-rate'),
        headers: await _headers(),
        body: jsonEncode({
          'bpm': bpm,
          'recorded_at': _toMysqlDateTime(time),
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> saveBloodPressure(int sys, int dia, DateTime time) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/blood-pressure'),
        headers: await _headers(),
        body: jsonEncode({
          'systolic': sys,
          'diastolic': dia,
          'recorded_at': _toMysqlDateTime(time),
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getHeartRateRecords() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/heart-rate'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getBloodPressureRecords() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/blood-pressure'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getVitalsTrends() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/vitals/trends'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('getVitalsTrends error: $e');
    }
    return {'success': false, 'trends': 'Failed to retrieve vitals trends.'};
  }



  static Future<Map<String, dynamic>> getDietPlan({String? dietType, bool regenerate = false}) async {
    try {
      final queryParam = '?dietType=${dietType ?? 'Vegetarian'}&regenerate=$regenerate';
      final res = await http.get(
        Uri.parse('$_baseUrl/wellness/diet-plan$queryParam'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('getDietPlan error: $e');
    }
    return {'success': false, 'dietPlan': 'Failed to compile diet plan.'};
  }

  // ─── APPOINTMENT REMINDERS ─────────────────────────────────────────────────

  static Future<bool> saveAppointmentReminder({
    required String date,
    String? place,
    String? time,
    String? purpose,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reminders'),
        headers: await _headers(),
        body: jsonEncode({
          'place': place,
          'date': date,
          'time': time,
          'purpose': purpose,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointmentReminders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/reminders'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> saveMedicineReminder({
    required String name,
    String? dose,
    String? meal,
    bool morning = false,
    String? morningTime,
    bool afternoon = false,
    String? afternoonTime,
    bool night = false,
    String? nightTime,
    List<String> repeatDays = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/medicine-reminders'),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          'dose': dose,
          'meal': meal,
          'morning': morning,
          'morning_time': morningTime,
          'afternoon': afternoon,
          'afternoon_time': afternoonTime,
          'night': night,
          'night_time': nightTime,
          'repeat_days': repeatDays,
        }),
      );
      if (kDebugMode) debugPrint('saveMedicineReminder: ${res.statusCode} ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('saveMedicineReminder error: $e');
      return false;
    }
  }

  static Future<String> checkDrugInteraction(String medicineName) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/medicine-reminders/check-interaction'),
        headers: await _headers(),
        body: jsonEncode({'name': medicineName}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['interaction'] ?? 'NO_INTERACTION';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('checkDrugInteraction error: $e');
    }
    return 'NO_INTERACTION';
  }

  static Future<List<Map<String, dynamic>>> getMedicineReminders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/medicine-reminders'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> saveTestReminder({
    required String name,
    String? meal,
    bool morning = false,
    String? morningTime,
    bool afternoon = false,
    String? afternoonTime,
    bool night = false,
    String? nightTime,
    List<String> repeatDays = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/test-reminders'),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          'meal': meal,
          'morning': morning,
          'morning_time': morningTime,
          'afternoon': afternoon,
          'afternoon_time': afternoonTime,
          'night': night,
          'night_time': nightTime,
          'repeat_days': repeatDays,
        }),
      );
      if (kDebugMode) debugPrint('saveTestReminder: ${res.statusCode} ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('saveTestReminder error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTestReminders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/test-reminders'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  // ─── DOCUMENTS ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadDocument({
    required String name,
    required String type,
    String? category,
    String? uploadFor,
    String? note,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('$_baseUrl/documents/upload');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['type'] = type;
      if (category != null) request.fields['category'] = category;
      if (uploadFor != null) request.fields['upload_for'] = uploadFor;
      if (note != null) request.fields['note'] = note;
      request.files.add(http.MultipartFile.fromBytes(
        'file', fileBytes, filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (kDebugMode) debugPrint('uploadDocument response: ${response.statusCode} ${response.body}');
      if (streamed.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Upload failed'};
    } catch (e) {
      if (kDebugMode) debugPrint('uploadDocument error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/documents'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteDocument(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/documents/$id'),
        headers: await _headers(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> analyzeDocument(int id) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/documents/$id/analyze'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      final err = jsonDecode(res.body);
      return {'success': false, 'message': err['message'] ?? 'Analysis failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> renameDocument(int id, String newName) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/documents/$id/rename'),
        headers: await _headers(),
        body: jsonEncode({'name': newName}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String resolveDocUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final root = _baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) {
      return '$root$url';
    }
    return '$root/$url';
  }

  // ─── AI CHAT (OLLAMA) ──────────────────────────────────────────────────────

  static Future<String> sendChatMessage(String message) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: await _headers(),
        body: jsonEncode({'message': message}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return data['reply'] as String;
      }
      return data['message'] as String? ?? 'Something went wrong. Please try again.';
    } catch (e) {
      if (kDebugMode) debugPrint('sendChatMessage error: $e');
      return 'Could not connect to the server. Please check your backend.';
    }
  }

  // ─── SUBSCRIPTION & FAMILY ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> upgradeSubscription(String plan) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/auth/upgrade'),
        headers: await _headers(),
        body: jsonEncode({'plan': plan}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/family'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getFamilyMembersResponse() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/family'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'success': false, 'data': [], 'subscriptionPlan': 'free'};
  }

  static Future<Map<String, dynamic>> addFamilyMember(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/family'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
