
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'payment_management_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'language_screen.dart';
import 'supervisor_detail_screen.dart';
import '../services/language_service.dart';


class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState
    extends State<SupervisorDashboardScreen> {
  bool loading = true;

  int ashaWorkers = 0;
  int beneficiaries = 0;
  int pregnancies = 0;
  int children = 0;
  int visits = 0;

  List<dynamic> ashaWorkerList = [];
  List<dynamic> beneficiaryList = [];
  List<dynamic> pregnancyList = [];
  List<dynamic> childList = [];
  List<dynamic> visitList = [];
  List<dynamic> villages = [];
  List<dynamic> todayWork = [];

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // =========================================================
  // LOAD ALL SUPERVISOR DATA
  // =========================================================

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = '';
      });
    }

    try {
      // Use ONE supervisor API response as the source of truth.
      // It contains counts + complete records from MySQL.
      final result = await ApiService.getDashboard();

      if (result is! Map) {
        throw Exception('Invalid supervisor dashboard response');
      }

      final data = Map<String, dynamic>.from(result);

      List<dynamic> listValue(String key) {
        final value = data[key];
        return value is List ? List<dynamic>.from(value) : <dynamic>[];
      }

      if (!mounted) return;

      setState(() {
        // Counts come directly from the database.
        ashaWorkers = _toInt(data['asha_workers']);
        beneficiaries = _toInt(data['beneficiaries']);
        pregnancies = _toInt(data['pregnancies']);
        children = _toInt(data['children']);
        visits = _toInt(data['visits']);

        // Full data comes from the same MySQL database.
        ashaWorkerList = listValue('asha_worker_details');
        beneficiaryList = listValue('beneficiary_data');
        pregnancyList = listValue('pregnancy_data');
        childList = listValue('child_data');
        visitList = listValue('visit_data');
        villages = listValue('villages');
        todayWork = listValue('today_work');

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Could not load supervisor data: $e';
      });
    }
  }

  String t(String key) => LanguageService.text(key);

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.logout, color: Colors.red),
          const SizedBox(width: 10),
          Text(t('logout')),
        ]),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('logout')),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldLogout || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_contact');
    await prefs.remove('user_id');
    await prefs.remove('user_village');
    await prefs.remove('user_mobile');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> openAllDetails(String titleKey) async {
    if (!mounted) return;
    try {
      List<dynamic> data;
      switch (titleKey) {
        case 'all_asha_workers':
          data = await ApiService.getAshaWorkers();
          break;
        case 'all_beneficiaries':
          data = await ApiService.getBeneficiaries();
          break;
        case 'all_pregnancies':
          data = await ApiService.getPregnancies();
          break;
        case 'all_children':
          data = await ApiService.getChildren();
          break;
        case 'all_visits':
          data = await ApiService.getVisits();
          break;
        default:
          data = const [];
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupervisorDetailScreen(
            titleKey: titleKey,
            records: data,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load details: $e')),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Converts Future<List<dynamic>> calls into safe lists.
  // If an endpoint is temporarily unavailable, the dashboard
  // does not crash.

  Future<List<dynamic>> _safeList(
    Future<List<dynamic>> Function() loader,
  ) async {
    try {
      final result = await loader();
      return List<dynamic>.from(result);
    } catch (_) {
      return [];
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('supervisor_dashboard'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: t('payments'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentManagementScreen())),
            icon: Icon(Icons.payments_outlined),
          ),
          IconButton(
            tooltip: t('messages'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen())),
            icon: Icon(Icons.message_outlined),
          ),
          IconButton(
            tooltip: t('notifications'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen())),
            icon: Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: t('language'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LanguageScreen())).then((_) { if (mounted) setState(() {}); }),
            icon: Icon(Icons.translate),
          ),
          IconButton(
            tooltip: t('refresh'),
            onPressed: loading ? null : loadDashboard,
            icon: Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: t('logout'),
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 10),
                  Text(t('logout'), style: const TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),

        ],
      ),

      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // HEADER
                    // =================================================

                    Text(
                      t('welcome_supervisor'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      t('monitor_text'),
                      style: TextStyle(fontSize: 15),
                    ),

                    SizedBox(height: 20),

                    // =================================================
                    // ERROR MESSAGE
                    // =================================================

                    if (errorMessage.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(errorMessage),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // =================================================
                    // OVERVIEW
                    // =================================================

                    Text(
                      t('overview'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: buildCard(
                            Icons.people,
                            t('asha_workers'),
                            ashaWorkers,
                            onTap: () => openAllDetails('all_asha_workers'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: buildCard(
                            Icons.family_restroom,
                            t('beneficiaries'),
                            beneficiaries,
                            onTap: () => openAllDetails('all_beneficiaries'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: buildCard(
                            Icons.pregnant_woman,
                            t('pregnancies'),
                            pregnancies,
                            onTap: () => openAllDetails('all_pregnancies'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: buildCard(
                            Icons.child_care,
                            t('children'),
                            children,
                            onTap: () => openAllDetails('all_children'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    buildWideCard(
                      Icons.medical_services,
                      t('total_visits'),
                      visits,
                      onTap: () => openAllDetails('all_visits'),
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // ASHA WORKERS
                    // =================================================

                    buildSectionTitle(
                      t('all_asha_workers'),
                      ashaWorkers,
                    ),

                    SizedBox(height: 10),

                    buildDataSection(
                      list: ashaWorkerList,
                      emptyMessage: t('no_data'),
                      builder: buildAshaWorkerCard,
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // BENEFICIARIES
                    // =================================================

                    buildSectionTitle(
                      t('all_beneficiaries'),
                      beneficiaries,
                    ),

                    SizedBox(height: 10),

                    buildDataSection(
                      list: beneficiaryList,
                      emptyMessage: t('no_data'),
                      builder: buildBeneficiaryCard,
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // PREGNANCIES
                    // =================================================

                    buildSectionTitle(
                      t('all_pregnancies'),
                      pregnancies,
                    ),

                    SizedBox(height: 10),

                    buildDataSection(
                      list: pregnancyList,
                      emptyMessage: t('no_data'),
                      builder: buildPregnancyCard,
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // CHILDREN
                    // =================================================

                    buildSectionTitle(
                      t('all_children'),
                      children,
                    ),

                    SizedBox(height: 10),

                    buildDataSection(
                      list: childList,
                      emptyMessage: t('no_data'),
                      builder: buildChildCard,
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // VISITS
                    // =================================================

                    buildSectionTitle(
                      t('all_visits'),
                      visits,
                    ),

                    SizedBox(height: 10),

                    buildDataSection(
                      list: visitList,
                      emptyMessage: t('no_data'),
                      builder: buildVisitCard,
                    ),

                    SizedBox(height: 28),

                    // =================================================
                    // TODAY'S WORK
                    // =================================================

                    buildSectionTitle(
                      t('todays_work'),
                      todayWork.length,
                    ),

                    SizedBox(height: 10),

                    if (todayWork.isEmpty)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t('no_work'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...todayWork.map(
                        (work) => buildTodayWorkCard(work),
                      ),

                    SizedBox(height: 28),

                    // =================================================
                    // VILLAGES
                    // =================================================

                    buildSectionTitle(
                      t('village_information'),
                      villages.length,
                    ),

                    SizedBox(height: 10),

                    if (villages.isEmpty)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            t('no_data'),
                          ),
                        ),
                      )
                    else
                      ...villages.map(
                        (village) => buildVillageCard(village),
                      ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget buildSectionTitle(
    String title,
    int count,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CircleAvatar(
          radius: 15,
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // GENERIC DATA SECTION
  // =========================================================

  Widget buildDataSection({
    required List<dynamic> list,
    required String emptyMessage,
    required Widget Function(dynamic) builder,
  }) {
    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Expanded(
                child: Text(emptyMessage),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: list
          .map(
            (item) => builder(item),
          )
          .toList(),
    );
  }

  // =========================================================
  // OVERVIEW CARD
  // =========================================================

  Widget buildCard(
    IconData icon,
    String title,
    int value, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              SizedBox(height: 10),
              Text(
                '$value',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // WIDE CARD
  // =========================================================

  Widget buildWideCard(
    IconData icon,
    String title,
    int value, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          size: 32,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ASHA WORKER CARD
  // =========================================================

  Widget buildAshaWorkerCard(
    dynamic worker,
  ) {
    final name = getValue(
      worker,
      [
        'name',
        'asha_name',
        'worker_name',
        'full_name',
      ],
      'ASHA Worker',
    );

    final phone = getValue(
      worker,
      [
        'phone',
        'mobile',
        'mobile_number',
        'phone_number',
      ],
      'Not available',
    );

    final village = getValue(
      worker,
      [
        'village',
        'village_name',
      ],
      'Not assigned',
    );

    final id = getValue(
      worker,
      [
        'id',
        'asha_id',
        'worker_id',
      ],
      '',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Village: $village',
        ),
        children: [
          buildInfoTile(
            Icons.badge,
            t('worker_id'),
            id,
          ),
          buildInfoTile(
            Icons.phone,
            t('mobile'),
            phone,
          ),
          buildInfoTile(
            Icons.location_on,
            t('village'),
            village,
          ),

          // Show any remaining fields from the API.
          buildExtraFields(
            worker,
            [
              'name',
              'asha_name',
              'worker_name',
              'full_name',
              'phone',
              'mobile',
              'mobile_number',
              'phone_number',
              'village',
              'village_name',
              'id',
              'asha_id',
              'worker_id',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BENEFICIARY CARD
  // =========================================================

  Widget buildBeneficiaryCard(
    dynamic beneficiary,
  ) {
    final name = getValue(
      beneficiary,
      [
        'name',
        'beneficiary_name',
        'full_name',
      ],
      'Beneficiary',
    );

    final phone = getValue(
      beneficiary,
      [
        'phone',
        'mobile',
        'mobile_number',
        'phone_number',
      ],
      'Not available',
    );

    final village = getValue(
      beneficiary,
      [
        'village',
        'village_name',
      ],
      'Not available',
    );

    final disease = getValue(
      beneficiary,
      [
        'disease',
        'disease_name',
        'health_condition',
        'condition',
      ],
      'Not selected',
    );

    final age = getValue(
      beneficiary,
      [
        'age',
      ],
      'Not available',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.person_outline),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Disease: $disease',
        ),
        children: [
          buildInfoTile(
            Icons.person,
            'Name',
            name,
          ),
          buildInfoTile(
            Icons.cake,
            'Age',
            age,
          ),
          buildInfoTile(
            Icons.phone,
            t('mobile'),
            phone,
          ),
          buildInfoTile(
            Icons.person_outline,
            'Gender',
            getValue(beneficiary, ['gender'], 'Not available'),
          ),
          buildInfoTile(
            Icons.location_on,
            t('village'),
            village,
          ),
          buildInfoTile(
            Icons.home_outlined,
            'Address',
            getValue(beneficiary, ['address'], 'Not available'),
          ),
          buildInfoTile(
            Icons.pregnant_woman,
            'Pregnancy',
            getValue(beneficiary, ['pregnancy_status'], 'Not specified'),
          ),
          buildInfoTile(
            Icons.groups,
            'VHNC',
            getValue(beneficiary, ['vhnc'], 'Not specified'),
          ),
          buildInfoTile(
            Icons.medical_information,
            'Disease / Condition',
            disease,
          ),

          buildExtraFields(
            beneficiary,
            [
              'name',
              'beneficiary_name',
              'full_name',
              'phone',
              'mobile',
              'mobile_number',
              'phone_number',
              'village',
              'village_name',
              'disease',
              'disease_name',
              'health_condition',
              'condition',
              'age',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PREGNANCY CARD
  // =========================================================

  Widget buildPregnancyCard(
    dynamic pregnancy,
  ) {
    final name = getValue(
      pregnancy,
      [
        'name',
        'beneficiary_name',
        'mother_name',
      ],
      'Pregnancy Record',
    );

    final village = getValue(
      pregnancy,
      [
        'village',
        'village_name',
      ],
      'Not available',
    );

    final expectedDate = getValue(
      pregnancy,
      [
        'expected_delivery_date',
        'edd',
        'delivery_date',
      ],
      'Not available',
    );

    final status = getValue(
      pregnancy,
      [
        'status',
        'pregnancy_status',
      ],
      'Active',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.pregnant_woman),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Status: $status',
        ),
        children: [
          buildInfoTile(
            Icons.person,
            'Mother / Beneficiary',
            name,
          ),
          buildInfoTile(
            Icons.location_on,
            t('village'),
            village,
          ),
          buildInfoTile(
            Icons.calendar_today,
            'Expected Delivery',
            expectedDate,
          ),
          buildInfoTile(
            Icons.info_outline,
            'Status',
            status,
          ),

          buildExtraFields(
            pregnancy,
            [
              'name',
              'beneficiary_name',
              'mother_name',
              'village',
              'village_name',
              'expected_delivery_date',
              'edd',
              'delivery_date',
              'status',
              'pregnancy_status',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHILD CARD
  // =========================================================

  Widget buildChildCard(
    dynamic child,
  ) {
    final name = getValue(
      child,
      [
        'name',
        'child_name',
        'full_name',
      ],
      'Child Record',
    );

    final age = getValue(
      child,
      [
        'age',
      ],
      'Not available',
    );

    final gender = getValue(
      child,
      [
        'gender',
        'sex',
      ],
      'Not available',
    );

    final village = getValue(
      child,
      [
        'village',
        'village_name',
      ],
      'Not available',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.child_care),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Age: $age',
        ),
        children: [
          buildInfoTile(
            Icons.person,
            'Name',
            name,
          ),
          buildInfoTile(
            Icons.cake,
            'Age',
            age,
          ),
          buildInfoTile(
            Icons.wc,
            'Gender',
            gender,
          ),
          buildInfoTile(
            Icons.location_on,
            t('village'),
            village,
          ),

          buildExtraFields(
            child,
            [
              'name',
              'child_name',
              'full_name',
              'age',
              'gender',
              'sex',
              'village',
              'village_name',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VISIT CARD
  // =========================================================

  Widget buildVisitCard(
    dynamic visit,
  ) {
    final beneficiary = getValue(
      visit,
      [
        'beneficiary_name',
        'name',
        'patient_name',
      ],
      'Beneficiary',
    );

    final worker = getValue(
      visit,
      [
        'asha_worker',
        'asha_name',
        'worker_name',
      ],
      'ASHA Worker',
    );

    final village = getValue(
      visit,
      [
        'village',
        'village_name',
      ],
      'Not available',
    );

    final date = getValue(
      visit,
      [
        'date',
        'visit_date',
        'created_at',
      ],
      'Not available',
    );

    final purpose = getValue(
      visit,
      [
        'purpose',
        'reason',
        'activity',
        'visit_type',
      ],
      'Health Visit',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.medical_services),
        ),
        title: Text(
          beneficiary,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$purpose • $date',
        ),
        children: [
          buildInfoTile(
            Icons.person,
            'Beneficiary',
            beneficiary,
          ),
          buildInfoTile(
            Icons.people,
            'ASHA Worker',
            worker,
          ),
          buildInfoTile(
            Icons.location_on,
            t('village'),
            village,
          ),
          buildInfoTile(
            Icons.calendar_today,
            'Visit Date',
            date,
          ),
          buildInfoTile(
            Icons.medical_services,
            'Purpose',
            purpose,
          ),

          buildExtraFields(
            visit,
            [
              'beneficiary_name',
              'name',
              'patient_name',
              'asha_worker',
              'asha_name',
              'worker_name',
              'village',
              'village_name',
              'date',
              'visit_date',
              'created_at',
              'purpose',
              'reason',
              'activity',
              'visit_type',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VILLAGE CARD
  // =========================================================

  Widget buildVillageCard(
    dynamic village,
  ) {
    final name = getValue(
      village,
      [
        'village',
        'village_name',
        'name',
      ],
      'Unknown Village',
    );

    final worker = getValue(
      village,
      [
        'asha_worker',
        'asha_name',
        'worker_name',
      ],
      'Not Assigned',
    );

    final beneficiaryCount = getValue(
      village,
      [
        'beneficiaries',
        'beneficiary_count',
      ],
      '0',
    );

    final pregnancyCount = getValue(
      village,
      [
        'pregnancies',
        'pregnancy_count',
      ],
      '0',
    );

    final childCount = getValue(
      village,
      [
        'children',
        'child_count',
      ],
      '0',
    );

    final visitCount = getValue(
      village,
      [
        'visits',
        'visit_count',
      ],
      '0',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(Icons.location_on),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'ASHA Worker: $worker',
        ),
        children: [
          buildInfoTile(
            Icons.people,
            t('beneficiaries'),
            beneficiaryCount,
          ),
          buildInfoTile(
            Icons.medical_services,
            'Visits',
            visitCount,
          ),
          buildInfoTile(
            Icons.pregnant_woman,
            t('pregnancies'),
            pregnancyCount,
          ),
          buildInfoTile(
            Icons.child_care,
            t('children'),
            childCount,
          ),

          buildExtraFields(
            village,
            [
              'village',
              'village_name',
              'name',
              'asha_worker',
              'asha_name',
              'worker_name',
              'beneficiaries',
              'beneficiary_count',
              'pregnancies',
              'pregnancy_count',
              'children',
              'child_count',
              'visits',
              'visit_count',
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TODAY'S WORK CARD
  // =========================================================

  Widget buildTodayWorkCard(
    dynamic work,
  ) {
    final asha = getValue(
      work,
      [
        'asha_worker',
        'asha_name',
        'worker_name',
      ],
      'ASHA Worker',
    );

    final village = getValue(
      work,
      [
        'village',
        'village_name',
      ],
      t('village'),
    );

    final task = getValue(
      work,
      [
        'task',
        'work',
        'activity',
      ],
      'Health Visit',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.notifications_active),
        ),
        title: Text(
          task,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'ASHA: $asha\nVillage: $village',
        ),
        isThreeLine: true,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }

  // =========================================================
  // INFORMATION TILE
  // =========================================================

  Widget buildInfoTile(
    IconData icon,
    String title,
    dynamic value,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 21),
      title: Text(title),
      trailing: SizedBox(
        width: 180,
        child: Text(
          value?.toString() ?? 'Not available',
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  // =========================================================
  // SHOW ALL OTHER FIELDS
  // =========================================================

  Widget buildExtraFields(
    dynamic data,
    List<String> alreadyShown,
  ) {
    if (data is! Map) {
      return SizedBox.shrink();
    }

    final excluded = alreadyShown
        .map((e) => e.toLowerCase())
        .toSet();

    final entries = data.entries.where(
      (entry) =>
          !excluded.contains(
            entry.key.toString().toLowerCase(),
          ),
    );

    return Column(
      children: entries.map(
        (entry) {
          return buildInfoTile(
            Icons.info_outline,
            formatKey(entry.key.toString()),
            entry.value,
          );
        },
      ).toList(),
    );
  }

  // =========================================================
  // VALUE HELPER
  // =========================================================

  String getValue(
    dynamic data,
    List<String> keys,
    String fallback,
  ) {
    if (data is! Map) {
      return fallback;
    }

    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  // =========================================================
  // FORMAT API FIELD NAME
  // =========================================================

  String formatKey(String key) {
    final result = key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (result.isEmpty) {
      return key;
    }

    return result
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) return word;

            return word[0].toUpperCase() +
                word.substring(1);
          },
        )
        .join(' ');
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  void showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 450,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Notifications",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 15),

                  Expanded(
                    child: todayWork.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 50,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No notifications today',
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: todayWork.map(
                              (work) {
                                final task = getValue(
                                  work,
                                  [
                                    'task',
                                    'work',
                                    'activity',
                                  ],
                                  'Scheduled Work',
                                );

                                final asha = getValue(
                                  work,
                                  [
                                    'asha_worker',
                                    'asha_name',
                                    'worker_name',
                                  ],
                                  'ASHA Worker',
                                );

                                return ListTile(
                                  leading: Icon(
                                    Icons.notifications,
                                  ),
                                  title: Text(task),
                                  subtitle: Text(
                                    'Assigned to $asha',
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

