import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.text('language'))),
      body: ValueListenableBuilder<String>(
        valueListenable: LanguageService.language,
        builder: (_, current, __) => ListView(
          padding: const EdgeInsets.all(16),
          children: LanguageService.supported.map((language) {
            return Card(
              child: RadioListTile<String>(
                value: language,
                groupValue: current,
                title: Text(language),
                secondary: const Icon(Icons.translate),
                onChanged: (value) async {
                  if (value != null) {
                    await LanguageService.setLanguage(value);
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
