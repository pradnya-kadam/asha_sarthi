import 'dart:async';

import 'dart:convert';

import '../config/server_config.dart';



import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:path/path.dart';

import 'package:sqflite/sqflite.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';



class DatabaseService {

  static Database? _database;



  // =====================================================

  // FASTAPI

  // =====================================================



  static const String apiBaseUrl = ServerConfig.baseUrl;



  // =====================================================

  // DATABASE

  // =====================================================



  static Future<Database> get database async {

    if (_database != null) {

      return _database!;

    }



    _database = await _initDatabase();

    return _database!;

  }



  // =====================================================

  // INITIALIZE DATABASE

  // =====================================================



  static Future<Database> _initDatabase() async {

    if (kIsWeb) {

      databaseFactory = databaseFactoryFfiWeb;

    }



    final databasePath = await getDatabasesPath();



    final path = join(

      databasePath,

      'ashasarthi.db',

    );



    return await openDatabase(

      path,

      version: 14,



      // ===================================================

      // CREATE

      // ===================================================



      onCreate: (db, version) async {



        // -------------------------------------------------

        // BENEFICIARIES

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE beneficiaries (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            name TEXT NOT NULL,

            age TEXT NOT NULL,

            gender TEXT NOT NULL,

            mobile TEXT NOT NULL,

            address TEXT NOT NULL,

            pregnancy_status TEXT,

            vhnc TEXT,

            disease TEXT,

            village TEXT,

            asha_worker TEXT,

            worker_email TEXT,

            asha_worker_name TEXT,

            asha_worker_id INTEGER,

            sync_id TEXT,

            sync_status TEXT DEFAULT 'pending'

          )

        ''');



        // -------------------------------------------------

        // VISITS

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE visits (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            beneficiary TEXT NOT NULL,

            purpose TEXT NOT NULL,

            visit_date TEXT NOT NULL,

            notes TEXT,

            village TEXT,

            asha_worker TEXT,

            status TEXT DEFAULT 'pending'

          )

        ''');



        // -------------------------------------------------

        // PREGNANCIES

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE pregnancies (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            beneficiary_name TEXT NOT NULL,

            age TEXT NOT NULL,

            mobile TEXT NOT NULL,

            address TEXT NOT NULL,

            id_number TEXT NOT NULL,

            trimester TEXT NOT NULL,

            delivery_date TEXT NOT NULL,

            photo_path TEXT NOT NULL,

            village TEXT,

            asha_worker TEXT

          )

        ''');



        // -------------------------------------------------

        // CHILDREN

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE children (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            name TEXT NOT NULL,

            age TEXT NOT NULL,

            gender TEXT NOT NULL,

            mobile TEXT NOT NULL,

            address TEXT NOT NULL,

            id_number TEXT NOT NULL,

            bcg_date TEXT,

            opv_birth_date TEXT,

            opv1_date TEXT,

            opv2_date TEXT,

            opv3_date TEXT,

            pentavalent1_date TEXT,

            pentavalent2_date TEXT,

            pentavalent3_date TEXT,

            measles1_date TEXT,

            measles2_date TEXT,

            dpt_booster_date TEXT,

            village TEXT,

            asha_worker TEXT

          )

        ''');



        // -------------------------------------------------

        // ASHA WORKERS

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE asha_workers (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            name TEXT NOT NULL,

            mobile TEXT,

            email TEXT,

            village TEXT NOT NULL

          )

        ''');



        // -------------------------------------------------

        // TODAY'S WORK

        // -------------------------------------------------



        await db.execute('''

          CREATE TABLE daily_work (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            asha_worker TEXT NOT NULL,

            village TEXT NOT NULL,

            beneficiary TEXT,

            task_type TEXT NOT NULL,

            task_description TEXT NOT NULL,

            work_date TEXT NOT NULL,

            status TEXT DEFAULT 'pending'

          )

        ''');



        await db.execute('''

          CREATE TABLE messages (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            sender_role TEXT NOT NULL,

            sender_name TEXT,

            sender_contact TEXT,

            receiver_role TEXT NOT NULL,

            receiver_name TEXT,

            receiver_contact TEXT,

            message TEXT NOT NULL,

            is_read INTEGER DEFAULT 0,

            created_at TEXT NOT NULL

          )

        ''');



        await db.execute('''

          CREATE TABLE notifications (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            recipient_role TEXT NOT NULL,

            recipient_contact TEXT,

            title TEXT NOT NULL,

            body TEXT NOT NULL,

            is_read INTEGER DEFAULT 0,

            created_at TEXT NOT NULL

          )

        ''');



        await db.execute('''

          CREATE TABLE local_users (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            name TEXT NOT NULL,

            role TEXT NOT NULL,

            email TEXT NOT NULL UNIQUE,

            password TEXT NOT NULL,

            mobile TEXT,

            village TEXT,

            created_at TEXT NOT NULL

          )

        ''');



        await db.execute('''

          CREATE TABLE payments (

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            asha_worker_id INTEGER,

            asha_worker_name TEXT NOT NULL,

            village TEXT,

            month TEXT NOT NULL,

            year INTEGER NOT NULL,

            completed_work INTEGER DEFAULT 0,

            pending_work INTEGER DEFAULT 0,

            base_amount REAL DEFAULT 0,

            additional_amount REAL DEFAULT 0,

            status TEXT DEFAULT 'Pending',

            payment_date TEXT,

            notes TEXT,

            sync_status TEXT DEFAULT 'pending',

            created_at TEXT NOT NULL

          )

        ''');

      },



      // ===================================================

      // DATABASE UPGRADE

      // ===================================================



      onUpgrade: (db, oldVersion, newVersion) async {



        // VERSION 1 -> 2

        if (oldVersion < 2) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS visits (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              beneficiary TEXT NOT NULL,

              purpose TEXT NOT NULL,

              visit_date TEXT NOT NULL,

              notes TEXT

            )

          ''');

        }



        // VERSION 2 -> 4

        if (oldVersion < 4) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS pregnancies (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              beneficiary_name TEXT NOT NULL,

              age TEXT NOT NULL,

              mobile TEXT NOT NULL,

              address TEXT NOT NULL,

              id_number TEXT NOT NULL,

              trimester TEXT NOT NULL,

              delivery_date TEXT NOT NULL,

              photo_path TEXT NOT NULL

            )

          ''');

        }



        // VERSION 4 -> 5

        if (oldVersion < 5) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS children (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              name TEXT NOT NULL,

              age TEXT NOT NULL,

              gender TEXT NOT NULL,

              mobile TEXT NOT NULL,

              address TEXT NOT NULL,

              id_number TEXT NOT NULL,

              bcg_date TEXT,

              opv_birth_date TEXT,

              opv1_date TEXT,

              opv2_date TEXT,

              opv3_date TEXT,

              pentavalent1_date TEXT,

              pentavalent2_date TEXT,

              pentavalent3_date TEXT,

              measles1_date TEXT,

              measles2_date TEXT,

              dpt_booster_date TEXT

            )

          ''');

        }



        // VERSION 5 -> 6

        if (oldVersion < 6) {

          await db.execute('''

            ALTER TABLE beneficiaries

            ADD COLUMN pregnancy_status TEXT

          ''');

        }



        // VERSION 6 -> 7

        if (oldVersion < 7) {

          await db.execute('''

            ALTER TABLE beneficiaries

            ADD COLUMN sync_status TEXT DEFAULT 'pending'

          ''');

        }



        // VERSION 7 -> 8

        if (oldVersion < 8) {

          // Existing version 8 had no structural changes.

        }



        // VERSION 8 -> 9

        if (oldVersion < 9) {



          // New beneficiary fields

          await _addColumnIfMissing(

            db,

            'beneficiaries',

            'vhnc',

            'TEXT',

          );



          await _addColumnIfMissing(

            db,

            'beneficiaries',

            'disease',

            'TEXT',

          );



          // Beneficiary village

          await _addColumnIfMissing(

            db,

            'beneficiaries',

            'village',

            'TEXT',

          );



          // Beneficiary ASHA

          await _addColumnIfMissing(

            db,

            'beneficiaries',

            'asha_worker',

            'TEXT',

          );



          // Visit fields

          await _addColumnIfMissing(

            db,

            'visits',

            'village',

            'TEXT',

          );



          await _addColumnIfMissing(

            db,

            'visits',

            'asha_worker',

            'TEXT',

          );



          await _addColumnIfMissing(

            db,

            'visits',

            'status',

            "TEXT DEFAULT 'pending'",

          );



          // Pregnancy fields

          await _addColumnIfMissing(

            db,

            'pregnancies',

            'village',

            'TEXT',

          );



          await _addColumnIfMissing(

            db,

            'pregnancies',

            'asha_worker',

            'TEXT',

          );



          // Children fields

          await _addColumnIfMissing(

            db,

            'children',

            'village',

            'TEXT',

          );



          await _addColumnIfMissing(

            db,

            'children',

            'asha_worker',

            'TEXT',

          );



          // ASHA table

          await db.execute('''

            CREATE TABLE IF NOT EXISTS asha_workers (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              name TEXT NOT NULL,

              mobile TEXT,

              email TEXT,

              village TEXT NOT NULL

            )

          ''');



          // Daily work table

          await db.execute('''

            CREATE TABLE IF NOT EXISTS daily_work (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              asha_worker TEXT NOT NULL,

              village TEXT NOT NULL,

              beneficiary TEXT,

              task_type TEXT NOT NULL,

              task_description TEXT NOT NULL,

              work_date TEXT NOT NULL,

              status TEXT DEFAULT 'pending'

            )

          ''');

        }



        if (oldVersion < 10) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS messages (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              sender_role TEXT NOT NULL,

              sender_name TEXT,

              sender_contact TEXT,

              receiver_role TEXT NOT NULL,

              receiver_name TEXT,

              receiver_contact TEXT,

              message TEXT NOT NULL,

              is_read INTEGER DEFAULT 0,

              created_at TEXT NOT NULL

            )

          ''');



          await db.execute('''

            CREATE TABLE IF NOT EXISTS notifications (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              recipient_role TEXT NOT NULL,

              recipient_contact TEXT,

              title TEXT NOT NULL,

              body TEXT NOT NULL,

              is_read INTEGER DEFAULT 0,

              created_at TEXT NOT NULL

            )

          ''');

        }



        // VERSION 10 -> 11

        if (oldVersion < 11) {

          await _addColumnIfMissing(

            db,

            'beneficiaries',

            'sync_id',

            'TEXT',

          );

        }



        if (oldVersion < 12) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS local_users (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              name TEXT NOT NULL,

              role TEXT NOT NULL,

              email TEXT NOT NULL UNIQUE,

              password TEXT NOT NULL,

              mobile TEXT,

              village TEXT,

              created_at TEXT NOT NULL

            )

          ''');

        }



        if (oldVersion < 13) {

          await db.execute('''

            CREATE TABLE IF NOT EXISTS payments (

              id INTEGER PRIMARY KEY AUTOINCREMENT,

              asha_worker_id INTEGER,

              asha_worker_name TEXT NOT NULL,

              village TEXT,

              month TEXT NOT NULL,

              year INTEGER NOT NULL,

              completed_work INTEGER DEFAULT 0,

              pending_work INTEGER DEFAULT 0,

              base_amount REAL DEFAULT 0,

              additional_amount REAL DEFAULT 0,

              status TEXT DEFAULT 'Pending',

              payment_date TEXT,

              notes TEXT,

              sync_status TEXT DEFAULT 'pending',

              created_at TEXT NOT NULL

            )

          ''');

        }
 
        // Version 14 repairs beneficiary columns for existing installations.
        if (oldVersion < 14) {
          await _addColumnIfMissing(db, 'beneficiaries', 'vhnc', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'disease', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'village', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'worker_email', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker_name', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker_id', 'INTEGER');
          await _addColumnIfMissing(db, 'beneficiaries', 'sync_id', 'TEXT');
          await _addColumnIfMissing(db, 'beneficiaries', 'sync_status', "TEXT DEFAULT 'pending'");
        }

      },
      onOpen: (db) async {
        await _addColumnIfMissing(db, 'beneficiaries', 'pregnancy_status', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'vhnc', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'disease', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'village', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'worker_email', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker_name', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'asha_worker_id', 'INTEGER');
        await _addColumnIfMissing(db, 'beneficiaries', 'sync_id', 'TEXT');
        await _addColumnIfMissing(db, 'beneficiaries', 'sync_status', "TEXT DEFAULT 'pending'");
      }
    );

  }



  // =====================================================

  // LOCAL OFFLINE AUTHENTICATION

  // =====================================================



  static String normalizeRole(String role) {

    final r = role.trim().toLowerCase().replaceAll('-', ' ').replaceAll('_', ' ');

    if (r == 'asha worker') return 'asha_worker';

    if (r == 'asha supervisor' || r == 'supervisor') return 'supervisor';

    if (r == 'beneficiary') return 'beneficiary';

    return r.replaceAll(' ', '_');

  }



  static Future<Map<String, dynamic>> saveLocalUser({

    required String name,

    required String role,

    required String email,

    required String password,

    String? mobile,

    String? village,

  }) async {

    final db = await database;

    final normalizedRole = normalizeRole(role);

    final normalizedEmail = email.trim().toLowerCase();

    final existing = await db.query(

      'local_users',

      where: 'LOWER(email) = ?',

      whereArgs: [normalizedEmail],

      limit: 1,

    );

    if (existing.isNotEmpty) {

      throw Exception('Email already registered on this phone');

    }

    final id = await db.insert('local_users', {

      'name': name.trim(),

      'role': normalizedRole,

      'email': normalizedEmail,

      'password': password,

      'mobile': mobile?.trim(),

      'village': village?.trim(),

      'created_at': DateTime.now().toIso8601String(),

    });

    return {

      'id': id,

      'name': name.trim(),

      'email': normalizedEmail,

      'role': normalizedRole,

      'mobile': mobile?.trim() ?? '',

      'village': village?.trim() ?? '',

    };

  }



  static Future<Map<String, dynamic>?> authenticateLocalUser({

    required String email,

    required String password,

    required String role,

  }) async {

    final db = await database;

    final normalizedRole = normalizeRole(role);

    final rows = await db.query(

      'local_users',

      where: 'LOWER(email) = ? AND password = ? AND role = ?',

      whereArgs: [email.trim().toLowerCase(), password, normalizedRole],

      limit: 1,

    );

    if (rows.isEmpty) return null;

    return Map<String, dynamic>.from(rows.first);

  }



  // Cache a server account on this phone so the same account can be used

  // later without Wi-Fi or a browser.

  static Future<void> cacheUser(Map<String, dynamic> user, String password) async {

    final db = await database;

    final email = user['email']?.toString().trim().toLowerCase();

    if (email == null || email.isEmpty) return;

    final role = normalizeRole(user['role']?.toString() ?? 'asha_worker');

    final existing = await db.query('local_users', where: 'LOWER(email) = ?', whereArgs: [email], limit: 1);

    final values = {

      'name': user['name']?.toString() ?? 'User',

      'role': role,

      'email': email,

      'password': password,

      'mobile': user['mobile']?.toString() ?? '',

      'village': user['village']?.toString() ?? '',

      'created_at': DateTime.now().toIso8601String(),

    };

    if (existing.isEmpty) {

      await db.insert('local_users', values);

    } else {

      await db.update('local_users', values, where: 'id = ?', whereArgs: [existing.first['id']]);

    }

  }



  // =====================================================

  // SAFE ADD COLUMN

  // =====================================================



  static Future<void> _addColumnIfMissing(

    Database db,

    String table,

    String column,

    String type,

  ) async {

    final result = await db.rawQuery(

      'PRAGMA table_info($table)',

    );



    final exists = result.any(

      (row) => row['name'] == column,

    );



    if (!exists) {

      await db.execute(

        'ALTER TABLE $table ADD COLUMN $column $type',

      );

    }

  }



  // =====================================================

  // CLOUD SYNC HELPERS

  // =====================================================



  static Future<bool> _syncRecord(

    String endpoint,

    Map<String, dynamic> data,

  ) async {

    try {

      final response = await http

          .post(

            Uri.parse('$apiBaseUrl$endpoint'),

            headers: {

              'Content-Type': 'application/json',

              'Accept': 'application/json',

            },

            body: jsonEncode(data),

          )

          .timeout(const Duration(seconds: 3));



      debugPrint('SYNC $endpoint -> ${response.statusCode}');

      debugPrint('SYNC BODY: ${response.body}');



      return response.statusCode >= 200 &&

          response.statusCode < 300;

    } catch (e) {

      debugPrint('SYNC ERROR [$endpoint]: $e');

      return false;

    }

  }



  static bool _syncStartedThisSession = false;



  static Future<void> syncAllLocalData() async {

    if (_syncStartedThisSession) return;

    _syncStartedThisSession = true;



    try {

      final db = await database;



      // Only push unsynced beneficiaries. This prevents the dashboard

      // from re-uploading the entire local database every time it opens.

      final beneficiaries = await db.query(

        'beneficiaries',

        where: "sync_status IS NULL OR sync_status != ?",

        whereArgs: ['synced'],

      );



      await Future.wait(beneficiaries.map((row) async {

        final data = Map<String, dynamic>.from(row);

        data['sync_id'] ??=

            'beneficiary-${data['id']}-${data['mobile']}-${data['name']}';

        final ok = await _syncRecord('/sync/beneficiary', data);

        if (ok) {

          await db.update(

            'beneficiaries',

            {'sync_status': 'synced', 'sync_id': data['sync_id']},

            where: 'id = ?',

            whereArgs: [data['id']],

          );

        }

      }));



      // Existing records in the other tables are synced in parallel so

      // startup is not blocked by a long serial request chain.

      final batches = <Future<bool>>[];

      for (final row in await db.query('visits')) {

        batches.add(_syncRecord('/sync/visit', Map<String, dynamic>.from(row)));

      }

      for (final row in await db.query('pregnancies')) {

        batches.add(_syncRecord('/sync/pregnancy', Map<String, dynamic>.from(row)));

      }

      for (final row in await db.query('children')) {

        batches.add(_syncRecord('/sync/child', Map<String, dynamic>.from(row)));

      }

      if (batches.isNotEmpty) {

        await Future.wait(batches);

      }

    } catch (e) {

      debugPrint('Background sync error: $e');

    }

  }



  // =====================================================

  // BENEFICIARIES

  // =====================================================



  static Future<int> addBeneficiary(

    Map<String, dynamic> beneficiary,

  ) async {

    final db = await database;



    final data =

        Map<String, dynamic>.from(beneficiary);



    data['sync_status'] = 'pending';

    data['sync_id'] ??= 'beneficiary-${DateTime.now().microsecondsSinceEpoch}';



    return await db.insert(

      'beneficiaries',

      data,

    );

  }



  static Future<Map<String, dynamic>>

      addBeneficiaryAndSync(

    Map<String, dynamic> beneficiary,

  ) async {

    final localId = await addBeneficiary(beneficiary);



    // Return immediately after the local SQLite write. Cloud sync runs

    // in the background so poor network never makes the app feel slow.

    unawaited(_syncSingleBeneficiary(localId, beneficiary));



    return {

      'local_id': localId,

      'synced': false,

      'message': 'Saved locally. Syncing in background.',

    };

  }



  static Future<void> _syncSingleBeneficiary(

    int localId,

    Map<String, dynamic> beneficiary,

  ) async {

    try {

      final data = Map<String, dynamic>.from(beneficiary);

      data['sync_id'] ??= 'beneficiary-${DateTime.now().microsecondsSinceEpoch}';

      final ok = await _syncRecord('/sync/beneficiary', data);

      if (ok) {

        final db = await database;

        await db.update(

          'beneficiaries',

          {'sync_status': 'synced', 'sync_id': data['sync_id']},

          where: 'id = ?',

          whereArgs: [localId],

        );

      }

    } catch (e) {

      debugPrint('Beneficiary background sync error: $e');

    }

  }



  static Future<List<Map<String, dynamic>>>

      getBeneficiaries() async {



    final db = await database;



    return await db.query(

      'beneficiaries',

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      getBeneficiaryCount() async {



    final db = await database;



    final result =

        await db.rawQuery(

      'SELECT COUNT(*) as count '

      'FROM beneficiaries',

    );



    return result.first['count'] as int;

  }



  static Future<int>

      deleteBeneficiary(int id) async {



    final db = await database;



    return await db.delete(

      'beneficiaries',

      where: 'id = ?',

      whereArgs: [id],

    );

  }



  // =====================================================

  // VILLAGE-WISE BENEFICIARIES

  // =====================================================



  static Future<List<Map<String, dynamic>>>

      getBeneficiariesByVillage(

    String village,

  ) async {



    final db = await database;



    return await db.query(

      'beneficiaries',

      where: 'village = ?',

      whereArgs: [village],

      orderBy: 'id DESC',

    );

  }



  static Future<List<Map<String, dynamic>>>

      getBeneficiariesByAsha(

    String ashaWorker,

  ) async {



    final db = await database;



    return await db.query(

      'beneficiaries',

      where: 'asha_worker = ?',

      whereArgs: [ashaWorker],

      orderBy: 'id DESC',

    );

  }



  // =====================================================

  // VISITS

  // =====================================================



  static Future<int> addVisit(

    Map<String, String> visit,

  ) async {

    final db = await database;

    final id = await db.insert('visits', visit);



    unawaited(_syncRecord('/sync/visit', {

      ...visit,

      'status': visit['status'] ?? 'Pending',

    }));



    return id;

  }



  static Future<List<Map<String, dynamic>>>

      getVisits() async {



    final db = await database;



    return await db.query(

      'visits',

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      getVisitCount() async {



    final db = await database;



    final result =

        await db.rawQuery(

      'SELECT COUNT(*) as count '

      'FROM visits',

    );



    return result.first['count'] as int;

  }



  static Future<List<Map<String, dynamic>>>

      getVisitsByVillage(

    String village,

  ) async {



    final db = await database;



    return await db.query(

      'visits',

      where: 'village = ?',

      whereArgs: [village],

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      deleteVisit(int id) async {



    final db = await database;



    return await db.delete(

      'visits',

      where: 'id = ?',

      whereArgs: [id],

    );

  }



  // =====================================================

  // PREGNANCIES

  // =====================================================



  static Future<int> addPregnancy(

    Map<String, String> pregnancy,

  ) async {

    final db = await database;

    final id = await db.insert('pregnancies', pregnancy);



    unawaited(_syncRecord('/sync/pregnancy', pregnancy));



    return id;

  }



  static Future<List<Map<String, dynamic>>>

      getPregnancies() async {



    final db = await database;



    return await db.query(

      'pregnancies',

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      getPregnancyCount() async {



    final db = await database;



    final result =

        await db.rawQuery(

      'SELECT COUNT(*) as count '

      'FROM pregnancies',

    );



    return result.first['count'] as int;

  }



  static Future<List<Map<String, dynamic>>>

      getPregnanciesByVillage(

    String village,

  ) async {



    final db = await database;



    return await db.query(

      'pregnancies',

      where: 'village = ?',

      whereArgs: [village],

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      deletePregnancy(int id) async {



    final db = await database;



    return await db.delete(

      'pregnancies',

      where: 'id = ?',

      whereArgs: [id],

    );

  }



  // =====================================================

  // CHILDREN

  // =====================================================



  static Future<int> addChild(

    Map<String, String> child,

  ) async {

    final db = await database;

    final id = await db.insert('children', child);



    unawaited(_syncRecord('/sync/child', child));



    return id;

  }



  static Future<List<Map<String, dynamic>>>

      getChildren() async {



    final db = await database;



    return await db.query(

      'children',

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      getChildrenCount() async {



    final db = await database;



    final result =

        await db.rawQuery(

      'SELECT COUNT(*) as count '

      'FROM children',

    );



    return result.first['count'] as int;

  }



  static Future<List<Map<String, dynamic>>>

      getChildrenByVillage(

    String village,

  ) async {



    final db = await database;



    return await db.query(

      'children',

      where: 'village = ?',

      whereArgs: [village],

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      deleteChild(int id) async {



    final db = await database;



    return await db.delete(

      'children',

      where: 'id = ?',

      whereArgs: [id],

    );

  }



  // =====================================================

  // ASHA WORKERS

  // =====================================================



  static Future<int> addAshaWorker(

    Map<String, String> worker,

  ) async {



    final db = await database;



    return await db.insert(

      'asha_workers',

      worker,

    );

  }



  static Future<List<Map<String, dynamic>>>

      getAshaWorkers() async {



    final db = await database;



    return await db.query(

      'asha_workers',

      orderBy: 'village ASC, name ASC',

    );

  }



  static Future<List<Map<String, dynamic>>>

      getAshaWorkersByVillage(

    String village,

  ) async {



    final db = await database;



    return await db.query(

      'asha_workers',

      where: 'village = ?',

      whereArgs: [village],

      orderBy: 'name ASC',

    );

  }



  static Future<int>

      getAshaWorkerCount() async {



    final db = await database;



    final result =

        await db.rawQuery(

      'SELECT COUNT(*) as count '

      'FROM asha_workers',

    );



    return result.first['count'] as int;

  }



  // =====================================================

  // VILLAGES

  // =====================================================



  static Future<List<String>>

      getVillages() async {



    final db = await database;



    final result =

        await db.rawQuery('''

          SELECT DISTINCT village

          FROM asha_workers

          WHERE village IS NOT NULL

          AND village != ''

          ORDER BY village ASC

        ''');



    return result

        .map(

          (row) =>

              row['village']

                  .toString(),

        )

        .toList();

  }



  // =====================================================

  // DAILY WORK

  // =====================================================



  static Future<int> addDailyWork(

    Map<String, String> work,

  ) async {



    final db = await database;



    return await db.insert(

      'daily_work',

      work,

    );

  }



  static Future<List<Map<String, dynamic>>>

      getDailyWork() async {



    final db = await database;



    return await db.query(

      'daily_work',

      orderBy:

          'work_date DESC, id DESC',

    );

  }



  static Future<List<Map<String, dynamic>>>

      getTodayWork() async {



    final db = await database;



    final today =

        DateTime.now();



    final date =

        '${today.year}-'

        '${today.month.toString().padLeft(2, '0')}-'

        '${today.day.toString().padLeft(2, '0')}';



    return await db.query(

      'daily_work',

      where: 'work_date = ?',

      whereArgs: [date],

      orderBy: 'id DESC',

    );

  }



  static Future<List<Map<String, dynamic>>>

      getTodayWorkByVillage(

    String village,

  ) async {



    final db = await database;



    final today =

        DateTime.now();



    final date =

        '${today.year}-'

        '${today.month.toString().padLeft(2, '0')}-'

        '${today.day.toString().padLeft(2, '0')}';



    return await db.query(

      'daily_work',

      where:

          'village = ? AND work_date = ?',

      whereArgs: [

        village,

        date,

      ],

      orderBy: 'id DESC',

    );

  }



  static Future<int>

      updateWorkStatus(

    int id,

    String status,

  ) async {



    final db = await database;



    return await db.update(

      'daily_work',

      {

        'status': status,

      },

      where: 'id = ?',

      whereArgs: [id],

    );

  }



  // =====================================================

  // TODAY'S WORK COUNTS

  // =====================================================



  static Future<int>

      getTodayPendingWorkCount() async {



    final db = await database;



    final today =

        DateTime.now();



    final date =

        '${today.year}-'

        '${today.month.toString().padLeft(2, '0')}-'

        '${today.day.toString().padLeft(2, '0')}';



    final result =

        await db.rawQuery('''

          SELECT COUNT(*) as count

          FROM daily_work

          WHERE work_date = ?

          AND status != 'completed'

        ''', [date]);



    return result.first['count'] as int;

  }



  static Future<int>

      getTodayCompletedWorkCount() async {



    final db = await database;



    final today =

        DateTime.now();



    final date =

        '${today.year}-'

        '${today.month.toString().padLeft(2, '0')}-'

        '${today.day.toString().padLeft(2, '0')}';



    final result =

        await db.rawQuery('''

          SELECT COUNT(*) as count

          FROM daily_work

          WHERE work_date = ?

          AND status = 'completed'

        ''', [date]);



    return result.first['count'] as int;

  }



  // =====================================================

  // SUPERVISOR VILLAGE SUMMARY

  // =====================================================



  static Future<Map<String, int>>

      getVillageSummary(

    String village,

  ) async {



    final db = await database;



    final beneficiaries =

        await db.rawQuery(

      '''

      SELECT COUNT(*) as count

      FROM beneficiaries

      WHERE village = ?

      ''',

      [village],

    );



    final visits =

        await db.rawQuery(

      '''

      SELECT COUNT(*) as count

      FROM visits

      WHERE village = ?

      ''',

      [village],

    );



    final pregnancies =

        await db.rawQuery(

      '''

      SELECT COUNT(*) as count

      FROM pregnancies

      WHERE village = ?

      ''',

      [village],

    );



    final children =

        await db.rawQuery(

      '''

      SELECT COUNT(*) as count

      FROM children

      WHERE village = ?

      ''',

      [village],

    );



    return {

      'beneficiaries':

          beneficiaries.first['count'] as int,

      'visits':

          visits.first['count'] as int,

      'pregnancies':

          pregnancies.first['count'] as int,

      'children':

          children.first['count'] as int,

    };

  }

  // =====================================================

  // PAYMENTS (OFFLINE FIRST)

  // =====================================================



  static Future<int> addLocalPayment(Map<String, dynamic> payment) async {

    final db = await database;

    return db.insert('payments', {

      ...payment,

      'sync_status': 'pending',

      'created_at': payment['created_at'] ?? DateTime.now().toIso8601String(),

    });

  }



  static Future<List<Map<String, dynamic>>> getLocalPayments() async {

    final db = await database;

    return db.query('payments', orderBy: 'id DESC');

  }



  static Future<int> updateLocalPayment(int id, Map<String, dynamic> payment) async {

    final db = await database;

    return db.update('payments', {...payment, 'sync_status': 'pending'}, where: 'id = ?', whereArgs: [id]);

  }



  static Future<int> deleteLocalPayment(int id) async {

    final db = await database;

    return db.delete('payments', where: 'id = ?', whereArgs: [id]);

  }



  // =====================================================

  // MESSAGES + NOTIFICATIONS (OFFLINE CACHE)

  // =====================================================



  static Future<int> saveMessage(Map<String, dynamic> message) async {

    final db = await database;

    return db.insert('messages', {

      ...message,

      'created_at': message['created_at'] ?? DateTime.now().toIso8601String(),

    });

  }



  static Future<List<Map<String, dynamic>>> getLocalMessages() async {

    final db = await database;

    return db.query('messages', orderBy: 'id DESC');

  }



  static Future<int> saveNotification(Map<String, dynamic> notification) async {

    final db = await database;

    return db.insert('notifications', {

      ...notification,

      'created_at': notification['created_at'] ?? DateTime.now().toIso8601String(),

    });

  }



  static Future<List<Map<String, dynamic>>> getLocalNotifications() async {

    final db = await database;

    return db.query('notifications', orderBy: 'id DESC');

  }





}
