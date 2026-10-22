import 'package:flutter/material.dart';
import '../services/language_service.dart';

class BeneficiaryProfileScreen extends StatelessWidget {
  final Map<String, dynamic> beneficiary;

  const BeneficiaryProfileScreen({
    super.key,
    required this.beneficiary,
  });

  String t(String key) => LanguageService.text(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('beneficiary')),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // Profile header
            const CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              beneficiary['name'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // Personal Information
            _sectionTitle(
              'Personal Information',
            ),

            const SizedBox(height: 10),

            _infoCard(
              icon: Icons.cake,
              title: 'Age',
              value:
                  '${beneficiary['age'] ?? ''} years',
            ),

            _infoCard(
              icon: Icons.people,
              title: 'Gender',
              value:
                  beneficiary['gender'] ?? '',
            ),

            _infoCard(
              icon: Icons.phone,
              title: 'Mobile Number',
              value:
                  beneficiary['mobile'] ?? '',
            ),

            _infoCard(
              icon: Icons.home,
              title: 'Address',
              value:
                  beneficiary['address'] ?? '',
            ),

            const SizedBox(height: 20),

            // Visit History placeholder
            _sectionTitle(
              'Visit History',
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),

              child: const Column(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 40,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Visit history will appear here',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section title
  static Widget _sectionTitle(
    String title,
  ) {
    return Align(
      alignment: Alignment.centerLeft,

      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Information card
  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),

      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),

          child: Text(value),
        ),
      ),
    );
  }
}
