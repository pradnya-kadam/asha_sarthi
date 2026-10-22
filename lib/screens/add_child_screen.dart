import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() =>
      _AddChildScreenState();
}

class _AddChildScreenState
    extends State<AddChildScreen> {

  final _formKey =
      GlobalKey<FormState>();

  // =========================
  // TEXT CONTROLLERS
  // =========================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController ageController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController idController =
      TextEditingController();

  String? selectedGender;

  // =========================
  // VACCINE DATES
  // =========================

  DateTime? bcgDate;
  DateTime? opvBirthDate;
  DateTime? opv1Date;
  DateTime? opv2Date;
  DateTime? opv3Date;

  DateTime? pentavalent1Date;
  DateTime? pentavalent2Date;
  DateTime? pentavalent3Date;

  DateTime? measles1Date;
  DateTime? measles2Date;

  DateTime? dptBoosterDate;

  // =========================
  // SELECT DATE
  // =========================

  Future<DateTime?> selectDate(
    DateTime? currentDate,
  ) async {
    return await showDatePicker(
      context: context,
      initialDate:
          currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  // =========================
  // DATE FORMAT
  // =========================

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String displayDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not given';
    }

    return '${date.day}/'
        '${date.month}/'
        '${date.year}';
  }

  // =========================
  // SAVE CHILD
  // =========================

  Future<void> saveChild() async {

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final child = <String, String>{

      'name':
          nameController.text.trim(),

      'age':
          ageController.text.trim(),

      'gender':
          selectedGender ?? '',

      'mobile':
          mobileController.text.trim(),

      'address':
          addressController.text.trim(),

      'id_number':
          idController.text.trim(),

      // Vaccines

      'bcg_date':
          formatDate(bcgDate),

      'opv_birth_date':
          formatDate(opvBirthDate),

      'opv1_date':
          formatDate(opv1Date),

      'opv2_date':
          formatDate(opv2Date),

      'opv3_date':
          formatDate(opv3Date),

      'pentavalent1_date':
          formatDate(
        pentavalent1Date,
      ),

      'pentavalent2_date':
          formatDate(
        pentavalent2Date,
      ),

      'pentavalent3_date':
          formatDate(
        pentavalent3Date,
      ),

      'measles1_date':
          formatDate(
        measles1Date,
      ),

      'measles2_date':
          formatDate(
        measles2Date,
      ),

      'dpt_booster_date':
          formatDate(
        dptBoosterDate,
      ),
    };

    try {

      // =========================
      // SAVE TO SQLITE
      // =========================

      await DatabaseService.addChild(
        child,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Child saved successfully',
          ),
        ),
      );

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      // Return to Children screen
      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error saving child: $e',
          ),
        ),
      );

      debugPrint(
        'Error saving child: $e',
      );
    }
  }

  @override
  void dispose() {

    nameController.dispose();
    ageController.dispose();
    mobileController.dispose();
    addressController.dispose();
    idController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(

      // =========================
      // APP BAR
      // =========================

      appBar: AppBar(
        title:
            const Text(
          'Add Child',
        ),
      ),

      // =========================
      // BODY
      // =========================

      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child:
            Form(

          key: _formKey,

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =========================
              // TITLE
              // =========================

              const Text(
                'Child Information',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Enter the child details and vaccination information',

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =========================
              // NAME
              // =========================

              TextFormField(
                controller:
                    nameController,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Child Name',

                  hintText:
                      'Enter child name',

                  prefixIcon:
                      Icon(
                    Icons.child_care,
                  ),

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {

                    return
                        'Please enter child name';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================
              // AGE
              // =========================

              TextFormField(
                controller:
                    ageController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Age',

                  hintText:
                      'Enter age',

                  prefixIcon:
                      Icon(Icons.cake),

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {

                    return
                        'Please enter age';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================
              // GENDER
              // =========================

              DropdownButtonFormField<String>(
                value:
                    selectedGender,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Gender',

                  prefixIcon:
                      Icon(
                    Icons.people,
                  ),

                  border:
                      OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: 'Male',
                    child:
                        Text('Male'),
                  ),

                  DropdownMenuItem(
                    value: 'Female',
                    child:
                        Text('Female'),
                  ),

                  DropdownMenuItem(
                    value: 'Other',
                    child:
                        Text('Other'),
                  ),
                ],

                onChanged:
                    (value) {

                  setState(() {
                    selectedGender =
                        value;
                  });
                },

                validator:
                    (value) {

                  if (value == null) {
                    return
                        'Please select gender';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================
              // MOBILE
              // =========================

              TextFormField(
                controller:
                    mobileController,

                keyboardType:
                    TextInputType.phone,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Parent / Guardian Mobile',

                  hintText:
                      'Enter mobile number',

                  prefixIcon:
                      Icon(Icons.phone),

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {

                    return
                        'Please enter mobile number';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================
              // ADDRESS
              // =========================

              TextFormField(
                controller:
                    addressController,

                maxLines: 3,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Address',

                  hintText:
                      'Enter complete address',

                  prefixIcon:
                      Icon(Icons.home),

                  border:
                      OutlineInputBorder(),

                  alignLabelWithHint:
                      true,
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {

                    return
                        'Please enter address';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              // =========================
              // ID NUMBER
              // =========================

              TextFormField(
                controller:
                    idController,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Child ID / Birth Record Number',

                  hintText:
                      'Enter ID number',

                  prefixIcon:
                      Icon(Icons.badge),

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {

                    return
                        'Please enter ID number';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 30,
              ),

              // =========================
              // VACCINATION TITLE
              // =========================

              const Text(
                'Vaccination Details',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Select the date when each vaccine was given',

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =========================
              // VACCINES
              // =========================

              _vaccineTile(
                title: 'BCG',
                date: bcgDate,
                onTap: () async {

                  final date =
                      await selectDate(
                    bcgDate,
                  );

                  if (date != null) {

                    setState(() {
                      bcgDate = date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'OPV - Birth Dose',
                date:
                    opvBirthDate,
                onTap: () async {

                  final date =
                      await selectDate(
                    opvBirthDate,
                  );

                  if (date != null) {

                    setState(() {
                      opvBirthDate =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'OPV - 1st Dose',
                date:
                    opv1Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    opv1Date,
                  );

                  if (date != null) {

                    setState(() {
                      opv1Date = date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'OPV - 2nd Dose',
                date:
                    opv2Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    opv2Date,
                  );

                  if (date != null) {

                    setState(() {
                      opv2Date = date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'OPV - 3rd Dose',
                date:
                    opv3Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    opv3Date,
                  );

                  if (date != null) {

                    setState(() {
                      opv3Date = date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'Pentavalent - 1st Dose',
                date:
                    pentavalent1Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    pentavalent1Date,
                  );

                  if (date != null) {

                    setState(() {
                      pentavalent1Date =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'Pentavalent - 2nd Dose',
                date:
                    pentavalent2Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    pentavalent2Date,
                  );

                  if (date != null) {

                    setState(() {
                      pentavalent2Date =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'Pentavalent - 3rd Dose',
                date:
                    pentavalent3Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    pentavalent3Date,
                  );

                  if (date != null) {

                    setState(() {
                      pentavalent3Date =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'Measles / Rubella - 1st Dose',
                date:
                    measles1Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    measles1Date,
                  );

                  if (date != null) {

                    setState(() {
                      measles1Date =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'Measles / Rubella - 2nd Dose',
                date:
                    measles2Date,
                onTap: () async {

                  final date =
                      await selectDate(
                    measles2Date,
                  );

                  if (date != null) {

                    setState(() {
                      measles2Date =
                          date;
                    });
                  }
                },
              ),

              _vaccineTile(
                title:
                    'DPT Booster',
                date:
                    dptBoosterDate,
                onTap: () async {

                  final date =
                      await selectDate(
                    dptBoosterDate,
                  );

                  if (date != null) {

                    setState(() {
                      dptBoosterDate =
                          date;
                    });
                  }
                },
              ),

              const SizedBox(
                height: 30,
              ),

              // =========================
              // SAVE BUTTON
              // =========================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      saveChild,

                  icon:
                      const Icon(
                    Icons.save,
                  ),

                  label:
                      const Text(
                    'Save Child',

                    style:
                        TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Center(
                child: Text(
                  'Child information will be stored securely.',

                  style:
                      TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // VACCINE TILE
  // =========================

  Widget _vaccineTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child:
          ListTile(

        leading:
            CircleAvatar(
          child: Icon(
            date == null
                ? Icons.vaccines_outlined
                : Icons.check,
          ),
        ),

        title:
            Text(
          title,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle:
            Text(
          date == null
              ? 'Not given'
              : 'Given on: ${displayDate(date)}',
        ),

        trailing:
            IconButton(
          onPressed:
              onTap,

          icon:
              Icon(
            date == null
                ? Icons.calendar_month
                : Icons.edit_calendar,
          ),
        ),

        onTap:
            onTap,
      ),
    );
  }
}