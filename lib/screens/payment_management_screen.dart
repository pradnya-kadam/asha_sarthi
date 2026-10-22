import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends State<PaymentManagementScreen> {
  String t(String key) => LanguageService.text(key);
  List<dynamic> payments = [];
  List<dynamic> workers = [];

  bool isLoading = true;
  String searchText = '';

  final List<String> months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final paymentData = await ApiService.getPayments();
      final workerData = await ApiService.getAshaWorkers();

      if (!mounted) return;

      setState(() {
        payments = paymentData;
        workers = workerData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load payments: $e'),
        ),
      );
    }
  }

  int toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  double toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String currentMonth() {
    return months[DateTime.now().month - 1];
  }

  List<dynamic> get filteredPayments {
    if (searchText.trim().isEmpty) {
      return payments;
    }

    final query = searchText.toLowerCase();

    return payments.where((payment) {
      final worker =
          payment['asha_worker_name']?.toString().toLowerCase() ?? '';

      final village =
          payment['village']?.toString().toLowerCase() ?? '';

      final month =
          payment['month']?.toString().toLowerCase() ?? '';

      final status =
          payment['status']?.toString().toLowerCase() ?? '';

      return worker.contains(query) ||
          village.contains(query) ||
          month.contains(query) ||
          status.contains(query);
    }).toList();
  }

  // ============================================================
  // ADD PAYMENT
  // ============================================================

  Future<void> showAddPaymentDialog() async {
    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ASHA workers available.'),
        ),
      );
      return;
    }

    dynamic selectedWorker = workers.first;

    final monthController =
        TextEditingController(text: currentMonth());

    final yearController =
        TextEditingController(
      text: DateTime.now().year.toString(),
    );

    final completedController =
        TextEditingController(text: '0');

    final pendingController =
        TextEditingController(text: '0');

    final baseAmountController =
        TextEditingController(text: '0');

    final additionalAmountController =
        TextEditingController(text: '0');

    final notesController =
        TextEditingController();

    String selectedStatus = 'Pending';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final base =
                double.tryParse(
                      baseAmountController.text,
                    ) ??
                    0;

            final additional =
                double.tryParse(
                      additionalAmountController.text,
                    ) ??
                    0;

            final total = base + additional;

            return AlertDialog(
              title: Text(t('payments')),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<dynamic>(
                      value: selectedWorker,
                      decoration: InputDecoration(
                        labelText: t('asha_workers'),
                        border: OutlineInputBorder(),
                      ),
                      items: workers.map((worker) {
                        return DropdownMenuItem<dynamic>(
                          value: worker,
                          child: Text(
                            worker['name']?.toString() ??
                                'Unknown Worker',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedWorker = value;
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: monthController,
                      decoration: InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: completedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Completed Work',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: pendingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pending Work',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: baseAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Base Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller:
                          additionalAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Additional Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),

                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total Amount: ₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Paid',
                          child: Text('Paid'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('cancel')),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final year =
                        int.tryParse(
                      yearController.text.trim(),
                    );

                    if (year == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('Enter valid year'),
                        ),
                      );
                      return;
                    }

                    try {
                      await ApiService.addPayment(
                        ashaWorkerId:
                            toInt(selectedWorker['id']),
                        ashaWorkerName:
                            selectedWorker['name']
                                    ?.toString() ??
                                '',
                        village:
                            selectedWorker['village']
                                ?.toString(),
                        month:
                            monthController.text.trim(),
                        year: year,
                        completedWork:
                            toInt(
                          completedController.text,
                        ),
                        pendingWork:
                            toInt(
                          pendingController.text,
                        ),
                        baseAmount:
                            toDouble(
                          baseAmountController.text,
                        ),
                        additionalAmount:
                            toDouble(
                          additionalAmountController.text,
                        ),
                        status: selectedStatus,
                        notes:
                            notesController.text.trim(),
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment added successfully',
                          ),
                        ),
                      );

                      await loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('Error: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    monthController.dispose();
    yearController.dispose();
    completedController.dispose();
    pendingController.dispose();
    baseAmountController.dispose();
    additionalAmountController.dispose();
    notesController.dispose();
  }

  // ============================================================
  // EDIT PAYMENT
  // ============================================================

  Future<void> showEditPaymentDialog(
    dynamic payment,
  ) async {
    dynamic selectedWorker;

    for (final worker in workers) {
      if (toInt(worker['id']) ==
          toInt(payment['asha_worker_id'])) {
        selectedWorker = worker;
        break;
      }
    }

    selectedWorker ??= {
      'id': payment['asha_worker_id'],
      'name': payment['asha_worker_name'],
      'village': payment['village'],
    };

    final monthController = TextEditingController(
      text: payment['month']?.toString() ?? '',
    );

    final yearController = TextEditingController(
      text: payment['year']?.toString() ??
          DateTime.now().year.toString(),
    );

    final completedController = TextEditingController(
      text: payment['completed_work']?.toString() ?? '0',
    );

    final pendingController = TextEditingController(
      text: payment['pending_work']?.toString() ?? '0',
    );

    final baseAmountController = TextEditingController(
      text: payment['base_amount']?.toString() ?? '0',
    );

    final additionalAmountController =
        TextEditingController(
      text:
          payment['additional_amount']?.toString() ?? '0',
    );

    final notesController = TextEditingController(
      text: payment['notes']?.toString() ?? '',
    );

    String selectedStatus =
        payment['status']?.toString() ?? 'Pending';

    if (selectedStatus != 'Paid' &&
        selectedStatus != 'Pending') {
      selectedStatus = 'Pending';
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final base =
                double.tryParse(
                      baseAmountController.text,
                    ) ??
                    0;

            final additional =
                double.tryParse(
                      additionalAmountController.text,
                    ) ??
                    0;

            final total = base + additional;

            return AlertDialog(
              title: Text(t('payments')),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<dynamic>(
                      value: selectedWorker,
                      decoration: InputDecoration(
                        labelText: t('asha_workers'),
                        border: OutlineInputBorder(),
                      ),
                      items: workers.map((worker) {
                        return DropdownMenuItem<dynamic>(
                          value: worker,
                          child: Text(
                            worker['name']?.toString() ??
                                'Unknown Worker',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedWorker = value;
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: monthController,
                      decoration: InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: completedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Completed Work',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: pendingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pending Work',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: baseAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Base Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller:
                          additionalAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Additional Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),

                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total Amount: ₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Paid',
                          child: Text('Paid'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(t('cancel')),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final year =
                        int.tryParse(
                      yearController.text.trim(),
                    );

                    if (year == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('Enter valid year'),
                        ),
                      );
                      return;
                    }

                    try {
                      // IMPORTANT:
                      // paymentId is a NAMED parameter.
                      await ApiService.updatePayment(
                        paymentId:
                            toInt(payment['id']),
                        ashaWorkerId:
                            toInt(selectedWorker['id']),
                        ashaWorkerName:
                            selectedWorker['name']
                                    ?.toString() ??
                                '',
                        village:
                            selectedWorker['village']
                                ?.toString(),
                        month:
                            monthController.text.trim(),
                        year: year,
                        completedWork:
                            toInt(
                          completedController.text,
                        ),
                        pendingWork:
                            toInt(
                          pendingController.text,
                        ),
                        baseAmount:
                            toDouble(
                          baseAmountController.text,
                        ),
                        additionalAmount:
                            toDouble(
                          additionalAmountController.text,
                        ),
                        status: selectedStatus,
                        notes:
                            notesController.text.trim(),
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment updated successfully',
                          ),
                        ),
                      );

                      await loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('Error: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    monthController.dispose();
    yearController.dispose();
    completedController.dispose();
    pendingController.dispose();
    baseAmountController.dispose();
    additionalAmountController.dispose();
    notesController.dispose();
  }

  // ============================================================
  // MARK PAYMENT AS PAID
  // ============================================================

  Future<void> markAsPaid(dynamic payment) async {
    final id = toInt(payment['id']);

    try {
      await ApiService.markPaymentPaid(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment marked as Paid',
          ),
        ),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to mark as paid: $e'),
        ),
      );
    }
  }

  // ============================================================
  // DELETE PAYMENT
  // ============================================================

  Future<void> deletePayment(dynamic payment) async {
    final id = toInt(payment['id']);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t('delete')),

          content: Text(
            'Are you sure you want to delete this payment record?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(t('cancel')),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(t('delete')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deletePayment(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment deleted successfully',
          ),
        ),
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to delete payment: $e'),
        ),
      );
    }
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget infoItem(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget paymentCard(dynamic payment) {
    final worker =
        payment['asha_worker_name']?.toString() ??
            'Unknown Worker';

    final village =
        payment['village']?.toString() ??
            'Unknown Village';

    final month =
        payment['month']?.toString() ?? '';

    final year =
        payment['year']?.toString() ?? '';

    final completed =
        toInt(payment['completed_work']);

    final pending =
        toInt(payment['pending_work']);

    final total =
        toDouble(payment['total_amount']);

    final status =
        payment['status']?.toString() ??
            'Pending';

    return Card(
      margin: EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,

      child: Padding(
        padding: EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    worker.isNotEmpty
                        ? worker[0].toUpperCase()
                        : 'A',
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        village,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: status == 'Paid'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Paid'
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: infoItem(
                    'Month',
                    '$month $year',
                  ),
                ),

                Expanded(
                  child: infoItem(
                    'Completed',
                    completed.toString(),
                  ),
                ),

                Expanded(
                  child: infoItem(
                    'Pending',
                    pending.toString(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    'Total Payment',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,

              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    showEditPaymentDialog(
                      payment,
                    );
                  },
                  icon:
                      Icon(Icons.edit),
                ),

                if (status != 'Paid')
                  IconButton(
                    tooltip: 'Mark Paid',
                    onPressed: () {
                      markAsPaid(payment);
                    },
                    icon: Icon(
                      Icons.check_circle,
                    ),
                  ),

                IconButton(
                  tooltip: t('delete'),
                  onPressed: () {
                    deletePayment(payment);
                  },
                  icon: Icon(
                    Icons.delete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,

        child: Padding(
          padding:
              EdgeInsets.all(12),

          child: Column(
            children: [
              Icon(
                icon,
                size: 27,
              ),

              SizedBox(height: 5),

              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),

              SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final paidCount = payments.where(
      (payment) =>
          payment['status']?.toString() ==
          'Paid',
    ).length;

    final pendingCount = payments.where(
      (payment) =>
          payment['status']?.toString() !=
          'Paid',
    ).length;

    final totalAmount =
        payments.fold<double>(
      0,
      (sum, payment) =>
          sum +
          toDouble(
            payment['total_amount'],
          ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Management',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadData,
            icon:
                Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            showAddPaymentDialog,
        icon: Icon(Icons.add),
        label:
            Text(t('payments')),
      ),

      body: Column(
        children: [
          // SEARCH
          Padding(
            padding:
                EdgeInsets.all(12),

            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },

              decoration:
                  InputDecoration(
                hintText:
                    'Search worker, village, month...',
                prefixIcon:
                    Icon(
                  Icons.search,
                ),

                suffixIcon:
                    searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                searchText =
                                    '';
                              });
                            },
                            icon:
                                Icon(
                              Icons.clear,
                            ),
                          )
                        : null,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),

          // SUMMARY
          Row(
            children: [
              summaryCard(
                'Total',
                payments.length
                    .toString(),
                Icons.receipt_long,
              ),

              summaryCard(
                'Paid',
                paidCount.toString(),
                Icons.check_circle,
              ),

              summaryCard(
                'Pending',
                pendingCount
                    .toString(),
                Icons.pending,
              ),
            ],
          ),

          Padding(
            padding:
                EdgeInsets.fromLTRB(
              16,
              6,
              16,
              8,
            ),

            child: Align(
              alignment:
                  Alignment.centerLeft,

              child: Text(
                'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // PAYMENT LIST
          Expanded(
            child: isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(),
                  )

                : filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .payments_outlined,
                              size: 70,
                              color: Colors
                                  .grey
                                  .shade400,
                            ),

                            SizedBox(
                              height: 12,
                            ),

                            Text(
                              searchText
                                      .isEmpty
                                  ? 'No payment records found'
                                  : 'No matching payments found',

                              style: TextStyle(
                                fontSize: 16,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      )

                    : RefreshIndicator(
                        onRefresh:
                            loadData,

                        child:
                            ListView.builder(
                          padding:
                              EdgeInsets
                                  .fromLTRB(
                            12,
                            4,
                            12,
                            100,
                          ),

                          itemCount:
                              filteredPayments
                                  .length,

                          itemBuilder:
                              (context,
                                  index) {
                            return paymentCard(
                              filteredPayments[
                                  index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}