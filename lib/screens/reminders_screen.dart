import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RemindersScreen extends StatefulWidget {
  final String workerEmail;

  const RemindersScreen({
    super.key,
    required this.workerEmail,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> reminders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    if (widget.workerEmail.trim().isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Worker email is not configured.';
      });
      return;
    }

    try {
      final result =
          await ApiService.getReminderResponses(widget.workerEmail);

      if (!mounted) return;

      setState(() {
        reminders = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not load reminders. Check the server.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit & Dose Reminders'),
        actions: [
          IconButton(
            onPressed: loadReminders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : reminders.isEmpty
                  ? const Center(
                      child: Text('No reminder responses found.'),
                    )
                  : RefreshIndicator(
                      onRefresh: loadReminders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.medication_outlined),
                              ),
                              title: Text(
                                reminder['beneficiary_name']?.toString() ??
                                    'Beneficiary',
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: ${reminder['reminder_type'] ?? 'Reminder'}',
                                  ),
                                  Text(
                                    'Item: ${reminder['item_name'] ?? '-'}',
                                  ),
                                  Text(
                                    'Status: ${reminder['status'] ?? '-'}',
                                  ),
                                  if (reminder['response_message'] != null)
                                    Text(
                                      'Reply: ${reminder['response_message']}',
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}