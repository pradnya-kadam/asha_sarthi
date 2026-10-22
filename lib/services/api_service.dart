import '../config/server_config.dart';

import 'database_service.dart';



import 'dart:convert';

import 'package:http/http.dart' as http;



class ApiService {

  // =====================================================

  // SERVER URL

  // =====================================================



  // API server URL.

  // Emulator default: http\://10.0.2.2:8000

  // Real phones on the same Wi-Fi: build/run with

  // --dart-define=API_BASE_URL=http\://YOUR_PC_IP:8000

  static const String baseUrl = ServerConfig.baseUrl;



  // =====================================================

  // HELPER

  // =====================================================



  static dynamic _decodeResponse(http.Response response) {

    if (response.body.isEmpty) {

      return {};

    }



    try {

      return jsonDecode(response.body);

    } catch (_) {

      return {};

    }

  }



  static List<dynamic> _listFromResponse(

    dynamic data,

    String key,

  ) {

    if (data is List) {

      return data;

    }



    if (data is Map && data[key] is List) {

      return List<dynamic>.from(data[key]);

    }



    return [];

  }



  // =====================================================

  // REGISTER

  // =====================================================



  static Future<Map<String, dynamic>> registerUser({

    required String name,

    required String role,

    required String email,

    required String password,

    String? village,

    String? mobile,

  }) async {

    // ALWAYS save on the phone first. No Wi-Fi/browser is required.

    try {

      final user = await DatabaseService.saveLocalUser(

        name: name,

        role: role,

        email: email,

        password: password,

        village: village,

        mobile: mobile,

      );



      // Optional cloud registration. It never blocks local registration.

      _registerRemoteInBackground(

        name: name,

        role: role,

        email: email,

        password: password,

        village: village,

        mobile: mobile,

      );



      return {

        'success': true,

        'offline': true,

        'data': user,

        'message': 'Account created and saved on this phone.',

      };

    } catch (e) {

      return {'success': false, 'message': e.toString()};

    }

  }



  static Future<void> _registerRemoteInBackground({

    required String name,

    required String role,

    required String email,

    required String password,

    String? village,

    String? mobile,

  }) async {

    try {

      await http.post(

        Uri.parse('$baseUrl/register'),

        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},

        body: jsonEncode({

          'name': name,

          'role': role,

          'email': email,

          'password': password,

          'village': village,

          'mobile': mobile,

        }),

      ).timeout(const Duration(seconds: 2));

    } catch (_) {

      // Offline is a valid mode; local data remains safe.

    }

  }



  // =====================================================

  // LOGIN

  // =====================================================



  static Future<Map<String, dynamic>> loginUser({

    required String email,

    required String password,

    required String role,

  }) async {

    // LOCAL FIRST: login works with airplane mode and no browser.

    final local = await DatabaseService.authenticateLocalUser(

      email: email,

      password: password,

      role: role,

    );

    if (local != null) {

      return {

        'success': true,

        'offline': true,

        'data': local,

        'message': 'Login successful (offline mode)',

      };

    }



    // If the account is not yet cached on this phone, try the server once.

    try {

      final response = await http.post(

        Uri.parse('$baseUrl/login'),

        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},

        body: jsonEncode({'email': email.trim(), 'password': password, 'role': role}),

      ).timeout(const Duration(seconds: 3));

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {

        final raw = data is Map && data['data'] is Map ? data['data'] : data;

        if (raw is Map) {

          final user = Map<String, dynamic>.from(raw);

          await DatabaseService.cacheUser(user, password);

          return {'success': true, 'data': user, 'message': 'Login successful'};

        }

      }

      return {

        'success': false,

        'message': data is Map ? (data['detail'] ?? data['message'] ?? 'Invalid email or password') : 'Invalid email or password',

      };

    } catch (_) {

      return {

        'success': false,

        'message': 'This account is not saved on this phone yet. Register/login once while connected, then it will work offline.',

      };

    }

  }



  // =====================================================

  // SYNC BENEFICIARY

  // =====================================================



  static Future<Map<String, dynamic>> syncBeneficiary(

    Map<String, dynamic> beneficiary,

  ) async {

    try {

      final response = await http.post(

        Uri.parse('$baseUrl/sync/beneficiary'),

        headers: {

          'Content-Type': 'application/json',

          'Accept': 'application/json',

        },

        body: jsonEncode({

          'local_id':

              beneficiary['local_id'] ?? beneficiary['id'],

          'name': beneficiary['name'],

          'age': beneficiary['age'],

          'gender': beneficiary['gender'],

          'mobile': beneficiary['mobile'],

          'address': beneficiary['address'],

          'pregnancy_status':

              beneficiary['pregnancy_status'],

          'disease': beneficiary['disease'],

          'vhnc': beneficiary['vhnc'],

          'asha_worker_id':

              beneficiary['asha_worker_id'],

          'asha_worker_name':

              beneficiary['asha_worker_name'],

          'village': beneficiary['village'],

          'village_id': beneficiary['village_id'],

        }),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode >= 200 &&

          response.statusCode < 300) {

        return {

          'success': true,

          'message': 'Beneficiary synced successfully',

          'data': data,

        };

      }



      return {

        'success': false,

        'message': 'Server error: ${response.body}',

      };

    } catch (e) {

      return {

        'success': false,

        'message': 'Connection error: $e',

      };

    }

  }



  // =====================================================

  // SUPERVISOR DASHBOARD

  // =====================================================



  static Future<Map<String, dynamic>> getDashboard() async {

    // Local SQLite is the primary source. This makes the supervisor

    // dashboard instant and usable without Wi-Fi.

    final asha = await DatabaseService.getAshaWorkers();

    final beneficiaries = await DatabaseService.getBeneficiaries();

    final pregnancies = await DatabaseService.getPregnancies();

    final children = await DatabaseService.getChildren();

    final visits = await DatabaseService.getVisits();

    final villages = await DatabaseService.getVillages();

    return {

      'asha_workers': asha.length,

      'beneficiaries': beneficiaries.length,

      'pregnancies': pregnancies.length,

      'children': children.length,

      'visits': visits.length,

      'asha_worker_details': asha,

      'beneficiary_data': beneficiaries,

      'pregnancy_data': pregnancies,

      'child_data': children,

      'visit_data': visits,

      'villages': villages,

      'today_work': <dynamic>[],

      'offline': true,

    };

  }



  // Keep compatibility with older screen code.

  static Future<Map<String, dynamic>>

      getSupervisorDashboard() async {

    return getDashboard();

  }



  // =====================================================

  // VILLAGE-WISE DATA

  // =====================================================



  static Future<List<dynamic>>

      getVillageWiseData() async {

    try {

      final response = await http.get(

        Uri.parse('$baseUrl/supervisor/village-wise'),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200) {

        return _listFromResponse(data, 'villages');

      }



      throw Exception(

        'Failed to load village-wise data',

      );

    } catch (e) {

      throw Exception(

        'Village-wise error: $e',

      );

    }

  }



  // =====================================================

  // VILLAGES

  // =====================================================



  static Future<List<dynamic>> getVillages() async {

    try {

      final response = await http.get(

        Uri.parse('$baseUrl/supervisor/villages'),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200) {

        return _listFromResponse(data, 'villages');

      }



      throw Exception('Failed to load villages');

    } catch (e) {

      throw Exception('Village error: $e');

    }

  }



  // =====================================================

  // ASHA WORKERS

  // =====================================================



  static Future<List<dynamic>> getAshaWorkers() async {

    return List<dynamic>.from(await DatabaseService.getAshaWorkers());

  }



  // =====================================================

  // BENEFICIARIES

  // =====================================================



  static Future<List<dynamic>> getBeneficiaries() async {

    return List<dynamic>.from(await DatabaseService.getBeneficiaries());

  }



  // =====================================================

  // VISITS

  // =====================================================



  static Future<List<dynamic>> getVisits() async {

    return List<dynamic>.from(await DatabaseService.getVisits());

  }



  // =====================================================

  // PREGNANCIES

  // =====================================================



  static Future<List<dynamic>> getPregnancies() async {

    return List<dynamic>.from(await DatabaseService.getPregnancies());

  }



  // =====================================================

  // CHILDREN

  // =====================================================



  static Future<List<dynamic>> getChildren() async {

    return List<dynamic>.from(await DatabaseService.getChildren());

  }



  // =====================================================

  // TODAY'S WORK

  // =====================================================



  static Future<List<dynamic>>

      getTodayWork() async {

    try {

      final response = await http.get(

        Uri.parse(

          '$baseUrl/supervisor/today-work',

        ),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200) {

        return _listFromResponse(

          data,

          'today_work',

        );

      }



      throw Exception(

        'Failed to load today work',

      );

    } catch (e) {

      throw Exception(

        'Today work error: $e',

      );

    }

  }



  // =====================================================

  // ASHA WORKER DETAILS

  // =====================================================



  static Future<Map<String, dynamic>>

      getAshaWorkerDetails(

    int ashaWorkerId,

  ) async {

    try {

      final response = await http.get(

        Uri.parse(

          '$baseUrl/supervisor/asha-workers/$ashaWorkerId',

        ),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200 &&

          data is Map) {

        return Map<String, dynamic>.from(data);

      }



      throw Exception(

        'Failed to load ASHA worker details',

      );

    } catch (e) {

      throw Exception(

        'ASHA details error: $e',

      );

    }

  }



  // =====================================================

  // ASHA VILLAGE DATA

  // =====================================================



  static Future<List<dynamic>>

      getAshaVillageData(

    int ashaWorkerId,

  ) async {

    try {

      final response = await http.get(

        Uri.parse(

          '$baseUrl/supervisor/asha-workers/$ashaWorkerId/data',

        ),

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200) {

        return _listFromResponse(data, 'data');

      }



      throw Exception(

        'Failed to load ASHA village data',

      );

    } catch (e) {

      throw Exception(

        'ASHA village data error: $e',

      );

    }

  }



  // =====================================================

  // PENDING WORK

  // =====================================================



  static Future<List<dynamic>>

      getPendingWork() async {

    try {

      final response = await http.get(

        Uri.parse(

          '$baseUrl/supervisor/pending-work',

        ),

        headers: const {

          'Accept': 'application/json',

        },

      ).timeout(const Duration(seconds: 5));



      final data = _decodeResponse(response);



      if (response.statusCode == 200) {

        return _listFromResponse(

          data,

          'pending_work',

        );

      }



      throw Exception(

        'Failed to load pending work',

      );

    } catch (e) {

      throw Exception(

        'Pending work error: $e',

      );

    }

  }



  // =====================================================

  // PAYMENTS - GET

  // =====================================================



  static Future<List<dynamic>> getPayments() async {

    return List<dynamic>.from(await DatabaseService.getLocalPayments());

  }



  // =====================================================

  // PAYMENTS - ADD

  // =====================================================



  // IMPORTANT:

  // These are NAMED parameters because

  // payment_management_screen.dart calls them this way.



  static Future<dynamic> addPayment({

    required int ashaWorkerId,

    required String ashaWorkerName,

    String? village,

    required String month,

    required int year,

    int completedWork = 0,

    int pendingWork = 0,

    double baseAmount = 0,

    double additionalAmount = 0,

    String status = 'Pending',

    String? paymentDate,

    String? notes,

  }) async {

    final body = {

      'asha_worker_id': ashaWorkerId,

      'asha_worker_name': ashaWorkerName,

      'village': village,

      'month': month,

      'year': year,

      'completed_work': completedWork,

      'pending_work': pendingWork,

      'base_amount': baseAmount,

      'additional_amount': additionalAmount,

      'status': status,

      'payment_date': paymentDate,

      'notes': notes,

    };

    final id = await DatabaseService.addLocalPayment(body);

    _paymentRemoteInBackground('POST', '$baseUrl/supervisor/payments', body);

    return {'success': true, 'offline': true, 'id': id, ...body};

  }



  // =====================================================

  // PAYMENTS - UPDATE

  // =====================================================



  // IMPORTANT:

  // paymentId is also a NAMED parameter.



  static Future<dynamic> updatePayment({

    required int paymentId,

    required int ashaWorkerId,

    required String ashaWorkerName,

    String? village,

    required String month,

    required int year,

    int completedWork = 0,

    int pendingWork = 0,

    double baseAmount = 0,

    double additionalAmount = 0,

    String status = 'Pending',

    String? paymentDate,

    String? notes,

  }) async {

    final body = {

      'asha_worker_id': ashaWorkerId,

      'asha_worker_name': ashaWorkerName,

      'village': village,

      'month': month,

      'year': year,

      'completed_work': completedWork,

      'pending_work': pendingWork,

      'base_amount': baseAmount,

      'additional_amount': additionalAmount,

      'status': status,

      'payment_date': paymentDate,

      'notes': notes,

    };

    await DatabaseService.updateLocalPayment(paymentId, body);

    _paymentRemoteInBackground('PUT', '$baseUrl/supervisor/payments/$paymentId', body);

    return {'success': true, 'offline': true, 'id': paymentId, ...body};

  }



  // =====================================================

  // PAYMENTS - MARK PAID

  // =====================================================



  static Future<dynamic> markPaymentPaid(int paymentId) async {

    await DatabaseService.updateLocalPayment(paymentId, {'status': 'Paid', 'payment_date': DateTime.now().toIso8601String()});

    _paymentRemoteInBackground('PUT', '$baseUrl/supervisor/payments/$paymentId/paid', {});

    return {'success': true, 'offline': true};

  }



  // =====================================================

  // PAYMENTS - DELETE

  // =====================================================



  static Future<dynamic> deletePayment(int paymentId) async {

    await DatabaseService.deleteLocalPayment(paymentId);

    try {

      await http.delete(Uri.parse('$baseUrl/supervisor/payments/$paymentId')).timeout(const Duration(seconds: 2));

    } catch (_) {}

    return {'success': true, 'offline': true};

  }



  static Future<void> _paymentRemoteInBackground(String method, String url, Map<String, dynamic> body) async {

    try {

      final uri = Uri.parse(url);

      if (method == 'POST') {

        await http.post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 2));

      } else {

        await http.put(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 2));

      }

    } catch (_) {}

  }



  // =====================================================

  // MESSAGES - GET

  // =====================================================



  static Future<List<dynamic>> getMessages({

    required String role,

    String? contact,

  }) async {

    final rows = await DatabaseService.getLocalMessages();

    final filtered = rows.where((m) {

      final roleMatch = m['sender_role']?.toString() == role || m['receiver_role']?.toString() == role;

      if (!roleMatch) return false;

      if (contact == null || contact.trim().isEmpty) return true;

      return m['sender_contact']?.toString() == contact.trim() || m['receiver_contact']?.toString() == contact.trim();

    }).toList();

    return List<dynamic>.from(filtered);

  }



  // =====================================================

  // MESSAGES - SEND

  // =====================================================



  static Future<dynamic> sendMessage({

    required String senderRole,

    required String senderName,

    required String senderContact,

    required String receiverRole,

    required String receiverName,

    required String receiverContact,

    required String message,

  }) async {

    final local = {

      'sender_role': senderRole,

      'sender_name': senderName,

      'sender_contact': senderContact,

      'receiver_role': receiverRole,

      'receiver_name': receiverName,

      'receiver_contact': receiverContact,

      'message': message,

      'is_read': 0,

      'created_at': DateTime.now().toIso8601String(),

    };

    final id = await DatabaseService.saveMessage(local);



    // Create a local notification for the receiver on this device.

    await DatabaseService.saveNotification({

      'recipient_role': receiverRole,

      'recipient_contact': receiverContact,

      'title': 'New message',

      'body': '$senderName: $message',

      'is_read': 0,

      'created_at': DateTime.now().toIso8601String(),

    });



    _sendMessageRemoteInBackground(local);

    return {'success': true, 'offline': true, 'id': id};

  }



  static Future<void> _sendMessageRemoteInBackground(Map<String, dynamic> data) async {

    try {

      await http.post(

        Uri.parse('$baseUrl/messages'),

        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},

        body: jsonEncode(data),

      ).timeout(const Duration(seconds: 2));

    } catch (_) {}

  }



  // =====================================================

  // NOTIFICATIONS - GET

  // =====================================================



  static Future<List<dynamic>> getNotifications({

    required String role,

    String? contact,

  }) async {

    final rows = await DatabaseService.getLocalNotifications();

    final filtered = rows.where((n) {

      if (n['recipient_role']?.toString() != role) return false;

      if (contact == null || contact.trim().isEmpty) return true;

      return n['recipient_contact']?.toString() == contact.trim();

    }).toList();

    return List<dynamic>.from(filtered);

  }



  // =====================================================

  // NOTIFICATIONS - MARK READ

  // =====================================================



  static Future<dynamic> markNotificationRead(int id) async {

    final db = await DatabaseService.database;

    await db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);

    return {'success': true, 'offline': true};

  }



  // =====================================================

  // UPDATE VISIT STATUS

  // =====================================================



  static Future<bool> updateVisitStatus({

    required int visitId,

    required String status,

  }) async {

    try {

      final response = await http.put(

        Uri.parse(

          '$baseUrl/supervisor/visits/$visitId/status',

        ),

        headers: const {

          'Content-Type': 'application/json',

          'Accept': 'application/json',

        },

        body: jsonEncode({

          'status': status,

        }),

      );



      return response.statusCode == 200;

    } catch (_) {

      return false;

    }

  }



  // =====================================================
  // VISIT / VACCINATION DOSE REMINDERS
  // Requires matching FastAPI endpoints in backend/main.py.
  // =====================================================

  static Future<Map<String, dynamic>> createReminder({
    required String beneficiaryName,
    required String beneficiaryMobile,
    required String workerName,
    required String workerMobile,
    String? workerEmail,
    required String reminderType, // "VISIT" or "DOSE"
    required String itemName,
    required DateTime dueAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reminders'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'beneficiary_name': beneficiaryName,
          'beneficiary_mobile': beneficiaryMobile,
          'worker_name': workerName,
          'worker_mobile': workerMobile,
          'worker_email': workerEmail,
          'reminder_type': reminderType.toUpperCase(),
          'item_name': itemName,
          'due_at': dueAt.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = _decodeResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic>
            ? data
            : {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': data is Map
            ? (data['detail'] ?? data['message'] ?? 'Failed to create reminder').toString()
            : 'Failed to create reminder (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Reminder connection error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getReminderResponses(
    String workerEmail,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/reminders/responses/${Uri.encodeComponent(workerEmail)}',
        ),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = _decodeResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rawList = data is List
            ? data
            : (data is Map && data['data'] is List
                ? data['data'] as List
                : <dynamic>[]);
        return rawList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception(
        data is Map
            ? (data['detail'] ?? 'Failed to load reminder responses')
            : 'Failed to load reminder responses',
      );
    } catch (e) {
      throw Exception('Reminder responses error: $e');
    }
  }
}
