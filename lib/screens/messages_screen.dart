import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> messages = [];
  List<dynamic> workers = [];
  bool loading = true;
  final messageController = TextEditingController();
  final receiverContactController = TextEditingController();
  final receiverNameController = TextEditingController();
  String receiverRole = 'beneficiary';
  String myRole = 'asha_worker';
  String myName = 'Asha Worker';
  String myContact = '';

  String t(String key) => LanguageService.text(key);

  @override
  void initState() { super.initState(); load(); }

  @override
  void dispose() { messageController.dispose(); receiverContactController.dispose(); receiverNameController.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      myRole = prefs.getString('user_role') ?? 'asha_worker';
      myName = prefs.getString('user_name') ?? 'Asha Worker';
      myContact = prefs.getString('user_contact') ?? '';
      final data = await ApiService.getMessages(role: myRole, contact: myContact);
      if (mounted) setState(() => messages = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to load messages: $e')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> send() async {
    final text = messageController.text.trim();
    final contact = receiverContactController.text.trim();
    if (text.isEmpty || contact.isEmpty) return;
    try {
      await ApiService.sendMessage(
        senderRole: myRole,
        senderName: myName,
        senderContact: myContact,
        receiverRole: receiverRole,
        receiverName: receiverNameController.text.trim().isEmpty ? 'User' : receiverNameController.text.trim(),
        receiverContact: contact,
        message: text,
      );
      messageController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t('messages')} sent. ${t('notifications')} will be generated.')));
      await load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('messages')), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          DropdownButtonFormField<String>(value: receiverRole, decoration: InputDecoration(labelText: t('send_to'), border: const OutlineInputBorder()), items: [
            DropdownMenuItem(value: 'beneficiary', child: Text(t('beneficiary'))),
            DropdownMenuItem(value: 'asha_worker', child: Text(t('asha_workers'))),
            DropdownMenuItem(value: 'supervisor', child: const Text('Supervisor')),
          ], onChanged: (v) => setState(() => receiverRole = v ?? 'beneficiary')),
          const SizedBox(height: 8),
          TextField(controller: receiverNameController, decoration: InputDecoration(labelText: t('receiver_name'), border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: receiverContactController, decoration: InputDecoration(labelText: t('receiver_contact'), border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: messageController, maxLines: 2, decoration: InputDecoration(labelText: t('message_reply'), border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: send, icon: const Icon(Icons.send), label: Text(t('send_message')))),
        ]))),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : messages.isEmpty ? Center(child: Text(t('no_messages'))) : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: messages.length,
          itemBuilder: (_, i) { final m = messages[i] as Map; final mine = m['sender_role']?.toString() == myRole && m['sender_contact']?.toString() == myContact; return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Card(child: Container(width: MediaQuery.of(context).size.width * .82, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${m['sender_name'] ?? 'User'} → ${m['receiver_name'] ?? 'User'}', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(m['message']?.toString() ?? ''), const SizedBox(height: 4), Text(m['created_at']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey))])))); },
        ))
      ]),
    );
  }
}
