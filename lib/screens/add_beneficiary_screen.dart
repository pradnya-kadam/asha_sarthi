

import 'dart:convert';



import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';



import '../services/database_service.dart';

import '../services/language_service.dart';



class AddBeneficiaryScreen extends StatefulWidget {

  AddBeneficiaryScreen({super.key});



  @override

  State<AddBeneficiaryScreen> createState() =>

      _AddBeneficiaryScreenState();

}



class _AddBeneficiaryScreenState

    extends State<AddBeneficiaryScreen> {

  String t(String key) => LanguageService.text(key);

  final _formKey = GlobalKey<FormState>();



  // =====================================================

  // CONTROLLERS

  // =====================================================



  final TextEditingController nameController =

      TextEditingController();



  final TextEditingController ageController =

      TextEditingController();



  final TextEditingController mobileController =

      TextEditingController();



  final TextEditingController addressController =

      TextEditingController();



  final TextEditingController diseaseController =

      TextEditingController();



  String? selectedGender;



  String? selectedVHNC;



  String? selectedDisease;



  bool isSaving = false;



  // =====================================================

  // FASTAPI URL

  // =====================================================



  // API server URL. For a real phone, use --dart-define=API_BASE_URL=http\://YOUR_PC_IP:8000

  static String get apiUrl => kIsWeb

      ? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http\://127.0.0.1:8000')

      : const String.fromEnvironment('API_BASE_URL', defaultValue: 'http\://10.0.2.2:8000');



  // =====================================================

  // DISPOSE

  // =====================================================



  @override

  void dispose() {

    nameController.dispose();

    ageController.dispose();

    mobileController.dispose();

    addressController.dispose();

    diseaseController.dispose();



    super.dispose();

  }



  // =====================================================

  // SAVE BENEFICIARY

  // =====================================================



  Future<void> saveBeneficiary() async {

    if (!_formKey.currentState!.validate()) {

      return;

    }



    if (isSaving) return;



    setState(() {

      isSaving = true;

    });



    // ===================================================

    // BENEFICIARY DATA

    // ===================================================



    final prefs = await SharedPreferences.getInstance();

    final beneficiary = {

      'name': nameController.text.trim(),

      'age': ageController.text.trim(),

      'gender': selectedGender ?? '',

      'mobile': mobileController.text.trim(),

      'address': addressController.text.trim(),

      'vhnc': selectedVHNC ?? 'No',

      'disease': selectedDisease ?? 'No Disease',

      // Central-server ownership fields so the supervisor can see

      // which ASHA worker created the record.

      'worker_email': prefs.getString('user_contact') ?? '',

      'asha_worker_name': prefs.getString('user_name') ?? '',

      'asha_worker_id': prefs.getInt('user_id'),

      'village': prefs.getString('user_village') ?? '',

    };



    try {

      // =================================================

      // STEP 1: SAVE LOCALLY

      // =================================================



      await DatabaseService.addBeneficiary(

        beneficiary,

      );



      // =================================================

      // STEP 2: TRY ONLINE SYNC

      // =================================================



      bool syncedOnline = false;



      try {

        final response = await http

            .post(

              Uri.parse(

                '$apiUrl/sync/beneficiary',

              ),

              headers: {

                'Content-Type': 'application/json',

              },

              body: jsonEncode(beneficiary),

            )

            .timeout(

              Duration(seconds: 5),

            );



        if (response.statusCode == 200) {

          syncedOnline = true;

        }

      } catch (_) {

        // Internet/FastAPI unavailable.

        // Data is already saved locally.

        syncedOnline = false;

      }



      if (!mounted) return;



      // =================================================

      // SHOW RESULT

      // =================================================



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            syncedOnline

                ? 'Beneficiary saved and synced online'

                : 'Beneficiary saved offline. It will sync later.',

          ),

        ),

      );



      await Future.delayed(

        Duration(milliseconds: 500),

      );



      if (!mounted) return;



      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            'Error saving beneficiary: $e',

          ),

        ),

      );

    } finally {

      if (mounted) {

        setState(() {

          isSaving = false;

        });

      }

    }

  }



  // =====================================================

  // BUILD

  // =====================================================



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(

          t('add_beneficiary'),

        ),

      ),



      body: SingleChildScrollView(

        padding: EdgeInsets.all(16),



        child: Form(

          key: _formKey,



          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment.start,



            children: [



              // =================================================

              // TITLE

              // =================================================



              Text(

                t('personal_information'),

                style: TextStyle(

                  fontSize: 22,

                  fontWeight: FontWeight.bold,

                ),

              ),



              SizedBox(height: 8),



              Text(

                'Enter the beneficiary details',

                style: TextStyle(

                  color: Colors.grey,

                  fontSize: 14,

                ),

              ),



              SizedBox(height: 20),



              // =================================================

              // NAME

              // =================================================



              TextFormField(

                controller: nameController,



                decoration:

                    InputDecoration(

                  labelText: t('full_name'),

                  hintText: 'Enter full name',

                  prefixIcon:

                      Icon(Icons.person),

                  border:

                      OutlineInputBorder(),

                ),



                validator: (value) {

                  if (value == null ||

                      value.trim().isEmpty) {

                    return 'Please enter name';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // AGE

              // =================================================



              TextFormField(

                controller: ageController,



                keyboardType:

                    TextInputType.number,



                decoration:

                    InputDecoration(

                  labelText: t('age'),

                  hintText: 'Enter age',

                  prefixIcon:

                      Icon(Icons.cake),

                  border:

                      OutlineInputBorder(),

                ),



                validator: (value) {

                  if (value == null ||

                      value.trim().isEmpty) {

                    return 'Please enter age';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // GENDER

              // =================================================



              DropdownButtonFormField<String>(

                value: selectedGender,



                decoration:

                    InputDecoration(

                  labelText: t('gender'),

                  prefixIcon:

                      Icon(Icons.people),

                  border:

                      OutlineInputBorder(),

                ),



                items: [

                  DropdownMenuItem(

                    value: 'Male',

                    child: Text('Male'),

                  ),



                  DropdownMenuItem(

                    value: 'Female',

                    child: Text('Female'),

                  ),



                  DropdownMenuItem(

                    value: 'Other',

                    child: Text('Other'),

                  ),

                ],



                onChanged: (value) {

                  setState(() {

                    selectedGender = value;

                  });

                },



                validator: (value) {

                  if (value == null) {

                    return 'Please select gender';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // MOBILE

              // =================================================



              TextFormField(

                controller: mobileController,



                keyboardType:

                    TextInputType.phone,



                decoration:

                    InputDecoration(

                  labelText: t('mobile_number'),

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

                    return 'Please enter mobile number';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // ADDRESS

              // =================================================



              TextFormField(

                controller: addressController,



                maxLines: 3,



                decoration:

                    InputDecoration(

                  labelText: 'Address',

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

                    return 'Please enter address';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // VHNC

              // =================================================



              DropdownButtonFormField<String>(

                value: selectedVHNC,



                decoration:

                    InputDecoration(

                  labelText: 'VHNC',

                  hintText:

                      'Select VHNC status',

                  prefixIcon:

                      Icon(Icons.groups),

                  border:

                      OutlineInputBorder(),

                ),



                items: [

                  DropdownMenuItem(

                    value: 'Yes',

                    child: Text(t('yes')),

                  ),



                  DropdownMenuItem(

                    value: 'No',

                    child: Text(t('no')),

                  ),

                ],



                onChanged: (value) {

                  setState(() {

                    selectedVHNC = value;

                  });

                },



                validator: (value) {

                  if (value == null) {

                    return 'Please select VHNC status';

                  }



                  return null;

                },

              ),



              SizedBox(height: 16),



              // =================================================

              // DISEASE

              // =================================================



              DropdownButtonFormField<String>(

                value: selectedDisease,



                decoration:

                    InputDecoration(

                  labelText: t('disease'),

                  hintText:

                      t('select_disease'),

                  prefixIcon:

                      Icon(Icons.medical_services),

                  border:

                      OutlineInputBorder(),

                ),



                items: [

                  DropdownMenuItem(

                    value: 'No Disease',

                    child: Text(t('no_disease')),

                  ),



                  DropdownMenuItem(

                    value: 'Diabetes',

                    child: Text(t('diabetes')),

                  ),



                  DropdownMenuItem(

                    value: 'Hypertension',

                    child: Text(t('hypertension')),

                  ),



                  DropdownMenuItem(

                    value: 'Tuberculosis',

                    child: Text(t('tuberculosis')),

                  ),



                  DropdownMenuItem(

                    value: 'Malaria',

                    child: Text(t('malaria')),

                  ),



                  DropdownMenuItem(

                    value: 'Anemia',

                    child: Text(t('anemia')),

                  ),



                  DropdownMenuItem(

                    value: 'Other',

                    child: Text('Other'),

                  ),

                ],



                onChanged: (value) {

                  setState(() {

                    selectedDisease = value;

                  });

                },



                validator: (value) {

                  if (value == null) {

                    return 'Please select disease status';

                  }



                  return null;

                },

              ),



              SizedBox(height: 30),



              // =================================================

              // SAVE BUTTON

              // =================================================



              SizedBox(

                width: double.infinity,

                height: 52,



                child:

                    ElevatedButton.icon(

                  onPressed: isSaving

                      ? null

                      : saveBeneficiary,



                  icon: isSaving

                      ? SizedBox(

                          width: 20,

                          height: 20,



                          child:

                              CircularProgressIndicator(

                            strokeWidth: 2,

                          ),

                        )

                      : Icon(

                          Icons.save,

                        ),



                  label: Text(

                    isSaving

                        ? 'Saving...'

                        : t('save'),



                    style:

                        TextStyle(

                      fontSize: 17,

                    ),

                  ),

                ),

              ),



              SizedBox(height: 10),



              // =================================================

              // INFO

              // =================================================



              Center(

                child: Text(

                  'Data will be saved offline and synced online when available.',

                  textAlign:

                      TextAlign.center,



                  style: TextStyle(

                    color: Colors.grey,

                    fontSize: 12,

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


