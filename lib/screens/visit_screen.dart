import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'record_visit_screen.dart';

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  State<VisitScreen> createState() =>
      _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  List<Map<String, dynamic>> visits = [];

  @override
  void initState() {
    super.initState();

    loadVisits();
  }

  // =========================
  // LOAD VISITS
  // =========================

  Future<void> loadVisits() async {
    try {
      final data =
          await DatabaseService.getVisits();

      if (!mounted) return;

      setState(() {
        visits = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading visits: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // OPEN RECORD VISIT FORM
  // =========================

  Future<void> openRecordVisit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RecordVisitScreen(),
      ),
    );

    // Refresh after returning
    await loadVisits();
  }

  // =========================
  // DELETE VISIT
  // =========================

  Future<void> deleteVisit(int id) async {
    try {
      await DatabaseService.deleteVisit(id);

      await loadVisits();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Visit deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error deleting visit: $e'),
        ),
      );
    }
  }

  // =========================
  // CONFIRM DELETE
  // =========================

  Future<void> confirmDelete(
    int id,
    String beneficiary,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Visit'),

          content: Text(
            'Are you sure you want to delete '
            'the visit for $beneficiary?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteVisit(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =========================
      // APP BAR
      // =========================

      appBar: AppBar(
        title:
            const Text('Visit Information'),

        actions: [
          IconButton(
            onPressed: loadVisits,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================

      body: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [

            // =========================
            // ADD RECORD VISIT BUTTON
            // =========================

            SizedBox(
              width:
                  double.infinity,

              height: 50,

              child:
                  ElevatedButton.icon(
                onPressed:
                    openRecordVisit,

                icon:
                    const Icon(
                  Icons.add,
                ),

                label:
                    const Text(
                  'Record New Visit',

                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =========================
            // VISIT LIST
            // =========================

            Expanded(
              child: visits.isEmpty

                  ? const Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          Icon(
                            Icons
                                .calendar_month,
                            size: 60,
                            color: Colors.grey,
                          ),

                          SizedBox(
                            height: 12,
                          ),

                          Text(
                            'No visits recorded yet',

                            style:
                                TextStyle(
                              fontSize: 18,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )

                  : ListView.builder(
                      itemCount:
                          visits.length,

                      itemBuilder:
                          (context, index) {

                        final visit =
                            visits[index];

                        final id =
                            visit['id'];

                        final beneficiary =
                            visit[
                                      'beneficiary']
                                  ?.toString() ??
                              '';

                        final purpose =
                            visit['purpose']
                                  ?.toString() ??
                              '';

                        final visitDate =
                            visit[
                                      'visit_date']
                                  ?.toString() ??
                              '';

                        final notes =
                            visit['notes']
                                  ?.toString() ??
                              '';

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),

                          child:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .all(12),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                // =================
                                // NAME + DELETE
                                // =================

                                Row(
                                  children: [

                                    const CircleAvatar(
                                      child:
                                          Icon(
                                        Icons.person,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child:
                                          Text(
                                        beneficiary,

                                        style:
                                            const TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        confirmDelete(
                                          id,
                                          beneficiary,
                                        );
                                      },

                                      icon:
                                          const Icon(
                                        Icons.delete,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                // =================
                                // PURPOSE
                                // =================

                                Row(
                                  children: [

                                    const Icon(
                                      Icons
                                          .medical_services_outlined,
                                      size: 20,
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    const Text(
                                      'Purpose: ',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          Text(
                                        purpose,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                // =================
                                // DATE
                                // =================

                                Row(
                                  children: [

                                    const Icon(
                                      Icons
                                          .calendar_month,
                                      size: 20,
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    const Text(
                                      'Date: ',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    Text(
                                      visitDate,
                                    ),
                                  ],
                                ),

                                // =================
                                // NOTES
                                // =================

                                if (notes
                                    .isNotEmpty) ...[

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      const Icon(
                                        Icons.notes,
                                        size: 20,
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      const Text(
                                        'Notes: ',

                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          notes,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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