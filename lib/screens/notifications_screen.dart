import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool loading = true;

  String t(String key) => LanguageService.text(key);

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'asha_worker';
      final contact = prefs.getString('user_contact');
      final data = await ApiService.getNotifications(role: role, contact: contact);
      if (mounted) setState(() => notifications = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to load notifications: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('notifications')), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(child: Text(t('no_notifications')))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifications[i] as Map;
                      final unread = (n['is_read']?.toString() ?? '0') != '1';
                      return Card(
                        child: ListTile(
                          leading: Icon(unread ? Icons.notifications_active : Icons.notifications_none),
                          title: Text(n['title']?.toString() ?? 'Notification', style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text(n['body']?.toString() ?? ''),
                          trailing: Text(n['created_at']?.toString().split('.').first ?? ''),
                          onTap: () async {
                            final id = int.tryParse(n['id']?.toString() ?? '');
                            if (id != null) await ApiService.markNotificationRead(id);
                            await load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
