import 'package:flutter/material.dart';
import '../services/language_service.dart';

class SupervisorDetailScreen extends StatefulWidget {
  final String titleKey;
  final List<dynamic> records;

  const SupervisorDetailScreen({super.key, required this.titleKey, required this.records});

  @override
  State<SupervisorDetailScreen> createState() => _SupervisorDetailScreenState();
}

class _SupervisorDetailScreenState extends State<SupervisorDetailScreen> {
  String query = '';

  String label(String key) => LanguageService.text(key);

  String prettyKey(String key) {
    final map = <String, String>{
      'id': label('details'),
      'name': label('name'),
      'asha_name': label('name'),
      'worker_name': label('name'),
      'full_name': label('name'),
      'mobile': label('mobile'),
      'phone': label('phone'),
      'email': label('email'),
      'village': label('village'),
      'village_name': label('village'),
      'age': label('age'),
      'gender': label('gender'),
      'address': label('address'),
      'disease': label('disease'),
      'disease_name': label('disease'),
      'status': label('status'),
    };
    return map[key] ?? key.replaceAll('_', ' ').replaceFirst(key[0], key[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.records.where((record) {
      if (query.trim().isEmpty) return true;
      return record.toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(label(widget.titleKey))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: label('details'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(label('no_data')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final record = filtered[index];
                      final map = record is Map ? Map<String, dynamic>.from(record) : <String, dynamic>{'value': record};
                      final displayName = map['name'] ?? map['beneficiary_name'] ?? map['asha_name'] ?? map['worker_name'] ?? '${label('details')} ${index + 1}';
                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(displayName.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${map.length} ${label('details').toLowerCase()}'),
                          children: map.entries.map((entry) {
                            final value = entry.value;
                            if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
                            return ListTile(
                              dense: true,
                              title: Text(prettyKey(entry.key), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(value.toString()),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
