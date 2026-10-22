import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/language_service.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  String t(String key) => LanguageService.text(key);
  List<Map<String, dynamic>> visits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVisits();
  }

  Future<void> loadVisits() async {
    setState(() {
      isLoading = true;
    });

    final data = await DatabaseService.getVisits();

    if (!mounted) return;

    setState(() {
      visits = data;
      isLoading = false;
    });
  }

  Future<void> deleteVisit(int id) async {
    await DatabaseService.deleteVisit(id);

    await loadVisits();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('visits')),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : visits.isEmpty
              ? const Center(
                  child: Text(
                    'No visits recorded yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadVisits,

                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      final visit = visits[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 12),

                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.medical_services,
                            ),
                          ),

                          title: Text(
                            visit['beneficiary'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Padding(
                            padding:
                                const EdgeInsets.only(top: 6),

                            child: Text(
                              'Purpose: ${visit['purpose'] ?? ''}\n'
                              'Date: ${visit['visit_date'] ?? ''}\n'
                              'Notes: ${visit['notes'] ?? ''}',
                            ),
                          ),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),

                            onPressed: () {
                              deleteVisit(
                                visit['id'] as int,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
