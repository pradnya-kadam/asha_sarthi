import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/language_service.dart';
import 'add_beneficiary_screen.dart';
import 'beneficiary_profile_screen.dart';

class BeneficiaryScreen extends StatefulWidget {
  BeneficiaryScreen({super.key});

  @override
  State<BeneficiaryScreen> createState() =>
      _BeneficiaryScreenState();
}

class _BeneficiaryScreenState
    extends State<BeneficiaryScreen> {
  String t(String key) => LanguageService.text(key);

  List<Map<String, dynamic>> beneficiaries = [];

  @override
  void initState() {
    super.initState();

    loadBeneficiaries();
  }

  // Load data from SQLite
  Future<void> loadBeneficiaries() async {
    try {
      final data =
          await DatabaseService.getBeneficiaries();

      if (!mounted) return;

      setState(() {
        beneficiaries = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading beneficiaries: $e',
          ),
        ),
      );
    }
  }

  // Open Add Beneficiary
  Future<void> openAddBeneficiary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddBeneficiaryScreen(),
      ),
    );

    // Reload database after returning
    await loadBeneficiaries();
  }

  // Delete beneficiary
  Future<void> deleteBeneficiary(int id) async {
    await DatabaseService.deleteBeneficiary(id);

    await loadBeneficiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('beneficiaries')),

        actions: [
          IconButton(
            onPressed: loadBeneficiaries,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(
          children: [

            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search beneficiary',

                prefixIcon:
                    Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Add Beneficiary
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: openAddBeneficiary,

                icon: Icon(
                  Icons.person_add,
                ),

                label: Text(
                  t('add_beneficiary'),

                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Beneficiary List
            Expanded(
              child: beneficiaries.isEmpty
                  ? Center(
                      child: Text(
                        'No beneficiaries added yet',

                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          beneficiaries.length,

                      itemBuilder:
                          (context, index) {

                        final beneficiary =
                            beneficiaries[index];

                        return Card(
                          margin:
                              EdgeInsets.only(
                            bottom: 12,
                          ),

                          child: ListTile(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BeneficiaryProfileScreen(
          beneficiary: beneficiary,
        ),
      ),
    );
  },

  leading: CircleAvatar(
    child: Icon(Icons.person),
  ),

                            title: Text(
                              beneficiary['name']
                                      ?.toString() ??
                                  '',

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              'Age: ${beneficiary['age']} • '
                              'Gender: ${beneficiary['gender']}\n'
                              'Mobile: ${beneficiary['mobile']}\n'
                              'Address: ${beneficiary['address']}',
                            ),

                            trailing:
                                IconButton(
                              icon: Icon(
                                Icons.delete,
                              ),

                              onPressed: () {
                                final id =
                                    beneficiary['id'];

                                deleteBeneficiary(id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}