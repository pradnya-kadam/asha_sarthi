import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/language_service.dart';

class RecordVisitScreen extends StatefulWidget {
  const RecordVisitScreen({super.key});

  @override
  State<RecordVisitScreen> createState() =>
      _RecordVisitScreenState();
}

class _RecordVisitScreenState
    extends State<RecordVisitScreen> {
  String t(String key) => LanguageService.text(key);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController beneficiaryController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  DateTime? selectedDate;

  String? selectedPurpose;

  // Select visit date
  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  // Save visit to SQLite
  Future<void> saveVisit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select visit date'),
        ),
      );
      return;
    }

    // Prepare visit data
    final visit = {
      'beneficiary':
          beneficiaryController.text.trim(),

      'purpose':
          selectedPurpose ?? '',

      'visit_date':
          '${selectedDate!.year}-'
          '${selectedDate!.month.toString().padLeft(2, '0')}-'
          '${selectedDate!.day.toString().padLeft(2, '0')}',

      'notes':
          notesController.text.trim(),
    };

    try {
      // Save to SQLite
      await DatabaseService.addVisit(visit);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Visit saved successfully',
          ),
        ),
      );

      // Return to previous screen
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving visit: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    beneficiaryController.dispose();
    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('record_visit')),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'Visit Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // BENEFICIARY NAME
              // =========================

              TextFormField(
                controller: beneficiaryController,

                decoration: const InputDecoration(
                  labelText: 'Beneficiary Name',
                  hintText:
                      'Enter beneficiary name',

                  prefixIcon:
                      Icon(Icons.person),

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return
                        'Please enter beneficiary name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // =========================
              // VISIT PURPOSE
              // =========================

              DropdownButtonFormField<String>(
                value: selectedPurpose,

                decoration:
                    const InputDecoration(
                  labelText: 'Visit Purpose',

                  prefixIcon: Icon(
                    Icons.medical_services,
                  ),

                  border:
                      OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: 'Vaccination',
                    child: Text(
                      'Vaccination',
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'Pregnancy Check-up',
                    child: Text(
                      'Pregnancy Check-up',
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'Child Health',
                    child: Text(
                      'Child Health',
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'General Check-up',
                    child: Text(
                      'General Check-up',
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'Follow-up',
                    child: Text(
                      'Follow-up',
                    ),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    selectedPurpose = value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return
                        'Please select visit purpose';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // =========================
              // VISIT DATE
              // =========================

              InkWell(
                onTap: selectDate,

                child: InputDecorator(
                  decoration:
                      const InputDecoration(
                    labelText: 'Visit Date',

                    prefixIcon: Icon(
                      Icons.calendar_month,
                    ),

                    border:
                        OutlineInputBorder(),
                  ),

                  child: Text(
                    selectedDate == null
                        ? 'Select visit date'
                        : '${selectedDate!.day}/'
                          '${selectedDate!.month}/'
                          '${selectedDate!.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // NOTES
              // =========================

              TextFormField(
                controller: notesController,

                maxLines: 4,

                decoration:
                    const InputDecoration(
                  labelText: 'Visit Notes',

                  hintText:
                      'Enter visit details',

                  prefixIcon:
                      Icon(Icons.notes),

                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // SAVE VISIT BUTTON
              // =========================

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton.icon(
                  onPressed: saveVisit,

                  icon: const Icon(
                    Icons.save,
                  ),

                  label: const Text(
                    'Save Visit',

                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
