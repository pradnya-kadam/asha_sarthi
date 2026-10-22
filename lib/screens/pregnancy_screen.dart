import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/database_service.dart';

class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() =>
      _PregnancyScreenState();
}

class _PregnancyScreenState
    extends State<PregnancyScreen> {

  final _formKey = GlobalKey<FormState>();

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

  String? selectedTrimester;

  DateTime? expectedDeliveryDate;

  String? photoPath;

  final ImagePicker imagePicker = ImagePicker();

  // =========================
  // SELECT PHOTO
  // =========================

  Future<void> selectPhoto() async {
    final XFile? image =
        await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        photoPath = image.path;
      });
    }
  }

  // =========================
  // SELECT DELIVERY DATE
  // =========================

  Future<void> selectDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        expectedDeliveryDate = date;
      });
    }
  }

  // =========================
  // SAVE PREGNANCY
  // =========================

  Future<void> savePregnancyRecord() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (expectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select expected delivery date',
          ),
        ),
      );
      return;
    }

    if (photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please capture beneficiary photo',
          ),
        ),
      );
      return;
    }

    final pregnancy = {
      'beneficiary_name':
          nameController.text.trim(),

      'age':
          ageController.text.trim(),

      'mobile':
          mobileController.text.trim(),

      'address':
          addressController.text.trim(),

      'id_number':
          idController.text.trim(),

      'trimester':
          selectedTrimester ?? '',

      'delivery_date':
          '${expectedDeliveryDate!.year}-'
          '${expectedDeliveryDate!.month.toString().padLeft(2, '0')}-'
          '${expectedDeliveryDate!.day.toString().padLeft(2, '0')}',

      'photo_path':
          photoPath!,
    };

    try {
      await DatabaseService.addPregnancy(
        pregnancy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pregnancy record saved successfully',
          ),
        ),
      );

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
            'Error saving pregnancy: $e',
          ),
        ),
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
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Pregnancy',
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Form(

          key: _formKey,

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'Pregnancy Information',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Record pregnancy details of the beneficiary',

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              // =========================
              // NAME
              // =========================

              TextFormField(
                controller:
                    nameController,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Beneficiary Name',

                  hintText:
                      'Enter name',

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
              // AGE
              // =========================

              TextFormField(
                controller:
                    ageController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText: 'Age',

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

              const SizedBox(height: 16),

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
                      'Mobile Number',

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

              const SizedBox(height: 16),

              // =========================
              // ADDRESS
              // =========================

              TextFormField(
                controller:
                    addressController,

                maxLines: 2,

                decoration:
                    const InputDecoration(
                  labelText: 'Address',

                  hintText:
                      'Enter address',

                  prefixIcon:
                      Icon(Icons.home),

                  border:
                      OutlineInputBorder(),
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

              const SizedBox(height: 16),

              // =========================
              // AADHAAR / ID
              // =========================

              TextFormField(
                controller:
                    idController,

                keyboardType:
                    TextInputType.number,

                maxLength: 12,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Aadhaar / ID Number *',

                  hintText:
                      'Enter ID number',

                  prefixIcon:
                      Icon(Icons.badge),

                  border:
                      OutlineInputBorder(),

                  counterText: '',
                ),

                validator: (value) {

                  if (value == null ||
                      value.trim().isEmpty) {
                    return
                        'ID number is required';
                  }

                  if (value.trim().length != 12) {
                    return
                        'Enter a valid 12-digit ID';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // =========================
              // TRIMESTER
              // =========================

              DropdownButtonFormField<String>(

                value:
                    selectedTrimester,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Pregnancy Trimester',

                  prefixIcon:
                      Icon(
                    Icons.pregnant_woman,
                  ),

                  border:
                      OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value:
                        'First Trimester',

                    child: Text(
                      'First Trimester',
                    ),
                  ),

                  DropdownMenuItem(
                    value:
                        'Second Trimester',

                    child: Text(
                      'Second Trimester',
                    ),
                  ),

                  DropdownMenuItem(
                    value:
                        'Third Trimester',

                    child: Text(
                      'Third Trimester',
                    ),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    selectedTrimester =
                        value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return
                        'Please select trimester';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // =========================
              // DELIVERY DATE
              // =========================

              InkWell(
                onTap:
                    selectDeliveryDate,

                child:
                    InputDecorator(

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Expected Delivery Date',

                    prefixIcon:
                        Icon(
                      Icons.calendar_month,
                    ),

                    border:
                        OutlineInputBorder(),
                  ),

                  child: Text(
                    expectedDeliveryDate ==
                            null
                        ? 'Select date'
                        : '${expectedDeliveryDate!.day}/'
                          '${expectedDeliveryDate!.month}/'
                          '${expectedDeliveryDate!.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // PHOTO
              // =========================

              const Text(
                'Beneficiary Photo *',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    OutlinedButton.icon(

                  onPressed:
                      selectPhoto,

                  icon:
                      const Icon(
                    Icons.camera_alt,
                  ),

                  label: Text(
                    photoPath == null
                        ? 'Capture Photo'
                        : 'Photo Captured ✓',
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // SAVE
              // =========================

              SizedBox(
                width:
                    double.infinity,

                height: 52,

                child:
                    ElevatedButton.icon(

                  onPressed:
                      savePregnancyRecord,

                  icon:
                      const Icon(
                    Icons.save,
                  ),

                  label: const Text(
                    'Save Pregnancy Record',

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