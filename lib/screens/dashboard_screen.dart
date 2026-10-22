import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../services/database_service.dart';
import 'beneficiary_screen.dart';
import 'record_visit_screen.dart';
import 'pregnancy_screen.dart';
import 'children_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'reminders_screen.dart';
import 'language_screen.dart';
import '../services/language_service.dart';

class DashboardScreen extends StatefulWidget {
  final String workerEmail;

  const DashboardScreen({
    super.key,
    this.workerEmail = '',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String t(String key) => LanguageService.text(key);

  int beneficiaryCount = 0;
  int visitCount = 0;
  int pregnancyCount = 0;
  int childrenCount = 0;

  List<Map<String, dynamic>> beneficiaries = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  // =====================================================
  // LOAD DASHBOARD DATA
  // =====================================================

  Future<void> loadAllData() async {
    try {
      // Sync local records with FastAPI/MySQL in the background.
      unawaited(DatabaseService.syncAllLocalData());

      final beneficiaryData =
          await DatabaseService.getBeneficiaries();

      final visits = await DatabaseService.getVisitCount();
      final pregnancies = await DatabaseService.getPregnancyCount();
      final children = await DatabaseService.getChildrenCount();

      if (!mounted) return;

      setState(() {
        beneficiaries = beneficiaryData;
        beneficiaryCount = beneficiaryData.length;
        visitCount = visits;
        pregnancyCount = pregnancies;
        childrenCount = children;
        loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard loading error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // =====================================================
  // OPEN SCREENS
  // =====================================================

  Future<void> openBeneficiaries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiaryScreen(),
      ),
    );

    await loadAllData();
  }

  Future<void> openVisits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordVisitScreen(),
      ),
    );

    await loadAllData();
  }

  Future<void> openPregnancy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PregnancyScreen(),
      ),
    );

    await loadAllData();
  }

  Future<void> openChildren() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildrenScreen(),
      ),
    );

    await loadAllData();
  }

  // =====================================================
  // VISIT AND DOSE REMINDERS
  // =====================================================

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemindersScreen(
          workerEmail: widget.workerEmail,
        ),
      ),
    );
  }

  // =====================================================
  // BENEFICIARY CARD
  // =====================================================

  Widget beneficiaryCard(Map<String, dynamic> beneficiary) {
    final name = beneficiary['name']?.toString() ?? 'Unknown';
    final age = beneficiary['age']?.toString() ?? '-';
    final gender = beneficiary['gender']?.toString() ?? '-';
    final mobile = beneficiary['mobile']?.toString() ?? '-';
    final address = beneficiary['address']?.toString() ?? '-';

    final pregnancy =
        beneficiary['pregnancy_status']?.toString() ??
            'Not specified';

    final syncStatus =
        beneficiary['sync_status']?.toString() ?? 'pending';

    final vhnc =
        beneficiary['vhnc']?.toString() ?? 'Not specified';

    final disease =
        beneficiary['disease']?.toString() ?? t('no_disease');

    final isSynced = syncStatus == 'synced';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSynced
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSynced ? 'Synced' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSynced
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.cake_outlined, t('age'), age),
            _infoRow(Icons.person_outline, t('gender'), gender),
            _infoRow(Icons.phone_outlined, t('mobile'), mobile),
            _infoRow(
              Icons.location_on_outlined,
              t('address'),
              address,
            ),
            _infoRow(
              Icons.pregnant_woman,
              t('pregnancy'),
              pregnancy,
            ),
            _infoRow(Icons.groups, 'VHNC', vhnc),
            _infoRow(
              Icons.medical_services_outlined,
              t('disease'),
              disease,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PROFILE
  // =====================================================

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 10),
            Text(t('my_profile')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileRow(
              Icons.person_outline,
              'Email',
              widget.workerEmail.isEmpty
                  ? 'Not available'
                  : widget.workerEmail,
            ),
            const SizedBox(height: 12),
            _profileRow(
              Icons.badge_outlined,
              'Role',
              'ASHA Worker',
            ),
            const SizedBox(height: 12),
            _profileRow(
              Icons.people_outline,
              t('beneficiaries'),
              beneficiaryCount.toString(),
            ),
            const SizedBox(height: 12),
            _profileRow(
              Icons.location_on_outlined,
              t('village'),
              'Local Village',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EDIT PROFILE
  // =====================================================

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: 'ASHA Worker');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_outlined),
            SizedBox(width: 10),
            Text('Edit Profile'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your name'),
                  ),
                );
                return;
              }

              if (passwordController.text.isNotEmpty &&
                  passwordController.text !=
                      confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Profile updated in this screen only.',
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(t('logout')),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(t('logout')),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DASHBOARD UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('dashboard')),
        actions: [
          IconButton(
            onPressed: _openReminders,
            icon: const Icon(Icons.medication_outlined),
            tooltip: 'Visit & Dose Reminders',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.message_outlined),
            tooltip: t('messages'),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: t('notifications'),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LanguageScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
            icon: const Icon(Icons.translate),
            tooltip: t('language'),
          ),
          IconButton(
            onPressed: loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: t('refresh'),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 17,
              child: Icon(Icons.person, size: 20),
            ),
            onSelected: (value) {
              if (value == 'profile') _showProfileDialog();
              if (value == 'edit') _showEditProfileDialog();
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Text(t('my_profile')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t('logout'),
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, ASHA Worker 👋',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage and view all health records',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 25),

                    // OVERVIEW
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            Icons.people,
                            t('beneficiaries'),
                            beneficiaryCount,
                            openBeneficiaries,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryCard(
                            Icons.calendar_month,
                            'Visits',
                            visitCount,
                            openVisits,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            Icons.pregnant_woman,
                            t('pregnancy'),
                            pregnancyCount,
                            openPregnancy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryCard(
                            Icons.child_care,
                            'Children',
                            childrenCount,
                            openChildren,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ALL BENEFICIARIES
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('all_beneficiaries'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: openBeneficiaries,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (beneficiaries.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 55,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No beneficiaries found',
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: openBeneficiaries,
                                  icon: const Icon(
                                    Icons.person_add,
                                  ),
                                  label: const Text(
                                    'Add Beneficiary',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...beneficiaries.map(
                        (beneficiary) =>
                            beneficiaryCard(beneficiary),
                      ),

                    const SizedBox(height: 20),

                    // OFFLINE AND SYNC STATUS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_done,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Data is saved offline and can sync '
                              'with FastAPI/MySQL.',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // =====================================================
  // SUMMARY CARD
  // =====================================================

  Widget _summaryCard(
    IconData icon,
    String title,
    int value,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(
                icon,
                size: 35,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}