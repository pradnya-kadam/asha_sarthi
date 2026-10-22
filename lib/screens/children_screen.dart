import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'add_child_screen.dart';
import '../services/language_service.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() =>
      _ChildrenScreenState();
}

class _ChildrenScreenState
    extends State<ChildrenScreen> {
  String t(String key) => LanguageService.text(key);

  List<Map<String, dynamic>> children = [];

  @override
  void initState() {
    super.initState();

    loadChildren();
  }

  // =========================
  // LOAD CHILDREN
  // =========================

  Future<void> loadChildren() async {
    try {
      final data =
          await DatabaseService.getChildren();

      if (!mounted) return;

      setState(() {
        children = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error loading children: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // OPEN ADD CHILD SCREEN
  // =========================

  Future<void> openAddChild() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddChildScreen(),
      ),
    );

    // Refresh list after returning
    await loadChildren();
  }

  // =========================
  // DELETE CHILD
  // =========================

  Future<void> deleteChild(int id) async {
    try {
      await DatabaseService.deleteChild(id);

      await loadChildren();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Child deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Error deleting child: $e'),
        ),
      );
    }
  }

  // =========================
  // CONFIRM DELETE
  // =========================

  Future<void> confirmDelete(
    int id,
    String name,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Child'),

          content: Text(
            'Are you sure you want to delete $name?',
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
      await deleteChild(id);
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
            Text(t('children')),

        actions: [
          IconButton(
            onPressed:
                loadChildren,

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
            // SEARCH
            // =========================

            TextField(
              decoration:
                  InputDecoration(
                hintText:
                    'Search child',

                prefixIcon:
                    const Icon(
                  Icons.search,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =========================
            // ADD CHILD BUTTON
            // =========================

            SizedBox(
              width:
                  double.infinity,

              height: 50,

              child:
                  ElevatedButton.icon(
                onPressed:
                    openAddChild,

                icon:
                    const Icon(
                  Icons.person_add,
                ),

                label:
                    const Text(
                  'Add Child',

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
            // CHILDREN LIST
            // =========================

            Expanded(
              child:
                  children.isEmpty

                      // EMPTY
                      ? const Center(
                          child: Text(
                            'No children added yet',

                            style:
                                TextStyle(
                              fontSize: 18,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        )

                      // LIST
                      : ListView.builder(
                          itemCount:
                              children.length,

                          itemBuilder:
                              (context, index) {

                            final child =
                                children[index];

                            final name =
                                child['name']
                                        ?.toString() ??
                                    '';

                            final age =
                                child['age']
                                        ?.toString() ??
                                    '';

                            final gender =
                                child['gender']
                                        ?.toString() ??
                                    '';

                            final mobile =
                                child['mobile']
                                        ?.toString() ??
                                    '';

                            final address =
                                child['address']
                                        ?.toString() ??
                                    '';

                            return Card(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),

                              child:
                                  ListTile(

                                // =================
                                // CHILD ICON
                                // =================

                                leading:
                                    const CircleAvatar(
                                  child:
                                      Icon(
                                    Icons.child_care,
                                  ),
                                ),

                                // =================
                                // CHILD NAME
                                // =================

                                title:
                                    Text(
                                  name,

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                // =================
                                // CHILD DETAILS
                                // =================

                                subtitle:
                                    Text(
                                  'Age: $age • '
                                  'Gender: $gender\n'
                                  'Mobile: $mobile\n'
                                  'Address: $address',
                                ),

                                // =================
                                // DELETE
                                // =================

                                trailing:
                                    IconButton(
                                  icon:
                                      const Icon(
                                    Icons.delete,
                                  ),

                                  onPressed: () {
                                    final id =
                                        child['id'];

                                    confirmDelete(
                                      id,
                                      name,
                                    );
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
