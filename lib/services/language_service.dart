import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const supported = ['English', 'मराठी', 'हिन्दी'];
  static const _key = 'app_language';
  static final ValueNotifier<String> language = ValueNotifier('English');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = prefs.getString(_key) ?? 'English';
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
    language.value = value;
  }

  static String text(String key) {
    const data = <String, Map<String, String>>{
      'app_name': {'English': 'AshaSarthi', 'मराठी': 'आशासारथी', 'हिन्दी': 'आशासारथी'},
      'dashboard': {'English': 'Dashboard', 'मराठी': 'डॅशबोर्ड', 'हिन्दी': 'डैशबोर्ड'},
      'supervisor_dashboard': {'English': 'Supervisor Dashboard', 'मराठी': 'पर्यवेक्षक डॅशबोर्ड', 'हिन्दी': 'पर्यवेक्षक डैशबोर्ड'},
      'beneficiaries': {'English': 'Beneficiaries', 'मराठी': 'लाभार्थी', 'हिन्दी': 'लाभार्थी'},
      'beneficiary': {'English': 'Beneficiary', 'मराठी': 'लाभार्थी', 'हिन्दी': 'लाभार्थी'},
      'add_beneficiary': {'English': 'Add Beneficiary', 'मराठी': 'लाभार्थी जोडा', 'हिन्दी': 'लाभार्थी जोड़ें'},
      'messages': {'English': 'Messages', 'मराठी': 'संदेश', 'हिन्दी': 'संदेश'},
      'notifications': {'English': 'Notifications', 'मराठी': 'सूचना', 'हिन्दी': 'सूचनाएँ'},
      'payments': {'English': 'Payments', 'मराठी': 'पेमेंट', 'हिन्दी': 'भुगतान'},
      'add_payment': {'English': 'Add Payment', 'मराठी': 'पेमेंट जोडा', 'हिन्दी': 'भुगतान जोड़ें'},
      'language': {'English': 'Language', 'मराठी': 'भाषा', 'हिन्दी': 'भाषा'},
      'disease': {'English': 'Disease', 'मराठी': 'आजार', 'हिन्दी': 'बीमारी'},
      'vhnc': {'English': 'VHNC', 'मराठी': 'VHNC', 'हिन्दी': 'VHNC'},
      'asha_workers': {'English': 'ASHA Workers', 'मराठी': 'आशा कार्यकर्त्या', 'हिन्दी': 'आशा कार्यकर्ता'},
      'pregnancies': {'English': 'Pregnancies', 'मराठी': 'गर्भधारणा', 'हिन्दी': 'गर्भावस्था'},
      'children': {'English': 'Children', 'मराठी': 'मुले', 'हिन्दी': 'बच्चे'},
      'visits': {'English': 'Visits', 'मराठी': 'भेटी', 'हिन्दी': 'दौरे'},
      'record_visit': {'English': 'Record Visit', 'मराठी': 'भेट नोंदवा', 'हिन्दी': 'दौरा दर्ज करें'},
      'total_visits': {'English': 'Total Visits', 'मराठी': 'एकूण भेटी', 'हिन्दी': 'कुल दौरे'},
      'overview': {'English': 'Overview', 'मराठी': 'आढावा', 'हिन्दी': 'अवलोकन'},
      'all_asha_workers': {'English': 'All ASHA Workers', 'मराठी': 'सर्व आशा कार्यकर्त्या', 'हिन्दी': 'सभी आशा कार्यकर्ता'},
      'all_beneficiaries': {'English': 'All Beneficiaries', 'मराठी': 'सर्व लाभार्थी', 'हिन्दी': 'सभी लाभार्थी'},
      'all_pregnancies': {'English': 'All Pregnancies', 'मराठी': 'सर्व गर्भधारणा', 'हिन्दी': 'सभी गर्भावस्थाएँ'},
      'all_children': {'English': 'All Children', 'मराठी': 'सर्व मुले', 'हिन्दी': 'सभी बच्चे'},
      'all_visits': {'English': 'All Visits', 'मराठी': 'सर्व भेटी', 'हिन्दी': 'सभी दौरे'},
      'todays_work': {'English': "Today's ASHA Work", 'मराठी': 'आजचे आशा काम', 'हिन्दी': 'आज का आशा कार्य'},
      'village_information': {'English': 'Village-wise Information', 'मराठी': 'गावनिहाय माहिती', 'हिन्दी': 'गाँव-वार जानकारी'},
      'welcome_supervisor': {'English': 'Welcome, Supervisor 👋', 'मराठी': 'स्वागत आहे, पर्यवेक्षक 👋', 'हिन्दी': 'स्वागत है, पर्यवेक्षक 👋'},
      'monitor_text': {'English': 'Monitor ASHA workers and village health activities.', 'मराठी': 'आशा कार्यकर्त्या आणि गावातील आरोग्य उपक्रमांचे निरीक्षण करा.', 'हिन्दी': 'आशा कार्यकर्ताओं और गाँव की स्वास्थ्य गतिविधियों की निगरानी करें।'},
      'refresh': {'English': 'Refresh', 'मराठी': 'रिफ्रेश', 'हिन्दी': 'रीफ्रेश'},
      'close': {'English': 'Close', 'मराठी': 'बंद करा', 'हिन्दी': 'बंद करें'},
      'details': {'English': 'Details', 'मराठी': 'तपशील', 'हिन्दी': 'विवरण'},
      'worker_id': {'English': 'Worker ID', 'मराठी': 'कार्यकर्ता आयडी', 'हिन्दी': 'कार्यकर्ता आईडी'},
      'mobile': {'English': 'Mobile', 'मराठी': 'मोबाईल', 'हिन्दी': 'मोबाइल'},
      'village': {'English': 'Village', 'मराठी': 'गाव', 'हिन्दी': 'गाँव'},
      'age': {'English': 'Age', 'मराठी': 'वय', 'हिन्दी': 'आयु'},
      'gender': {'English': 'Gender', 'मराठी': 'लिंग', 'हिन्दी': 'लिंग'},
      'address': {'English': 'Address', 'मराठी': 'पत्ता', 'हिन्दी': 'पता'},
      'phone': {'English': 'Phone', 'मराठी': 'फोन', 'हिन्दी': 'फ़ोन'},
      'email': {'English': 'Email', 'मराठी': 'ईमेल', 'हिन्दी': 'ईमेल'},
      'name': {'English': 'Name', 'मराठी': 'नाव', 'हिन्दी': 'नाम'},
      'status': {'English': 'Status', 'मराठी': 'स्थिती', 'हिन्दी': 'स्थिति'},
      'no_data': {'English': 'No data available.', 'मराठी': 'माहिती उपलब्ध नाही.', 'हिन्दी': 'कोई जानकारी उपलब्ध नहीं है।'},
      'no_work': {'English': 'No work scheduled for today.', 'मराठी': 'आज कोणतेही काम नियोजित नाही.', 'हिन्दी': 'आज कोई काम निर्धारित नहीं है।'},
      'select_language': {'English': 'Select Language', 'मराठी': 'भाषा निवडा', 'हिन्दी': 'भाषा चुनें'},
      'login': {'English': 'Login', 'मराठी': 'लॉगिन', 'हिन्दी': 'लॉगिन'},
      'register': {'English': 'Register', 'मराठी': 'नोंदणी', 'हिन्दी': 'रजिस्टर'},
      'logout': {'English': 'Logout', 'मराठी': 'लॉगआउट', 'हिन्दी': 'लॉगआउट'},
      'save': {'English': 'Save', 'मराठी': 'जतन करा', 'हिन्दी': 'सहेजें'},
      'cancel': {'English': 'Cancel', 'मराठी': 'रद्द करा', 'हिन्दी': 'रद्द करें'},
      'delete': {'English': 'Delete', 'मराठी': 'हटवा', 'हिन्दी': 'हटाएँ'},
      'add_child': {'English': 'Add Child', 'मराठी': 'मूल जोडा', 'हिन्दी': 'बच्चा जोड़ें'},
      'pregnancy': {'English': 'Pregnancy', 'मराठी': 'गर्भधारणा', 'हिन्दी': 'गर्भावस्था'},
      'my_profile': {'English': 'My Profile', 'मराठी': 'माझे प्रोफाइल', 'हिन्दी': 'मेरी प्रोफ़ाइल'},
      'send_to': {'English': 'Send to', 'मराठी': 'यांना पाठवा', 'हिन्दी': 'इन्हें भेजें'},
      'receiver_name': {'English': 'Receiver name', 'मराठी': 'प्राप्तकर्त्याचे नाव', 'हिन्दी': 'प्राप्तकर्ता का नाम'},
      'receiver_contact': {'English': 'Receiver email/mobile', 'मराठी': 'प्राप्तकर्त्याचा ईमेल/मोबाईल', 'हिन्दी': 'प्राप्तकर्ता ईमेल/मोबाइल'},
      'message_reply': {'English': 'Message / Reply', 'मराठी': 'संदेश / उत्तर', 'हिन्दी': 'संदेश / उत्तर'},
      'send_message': {'English': 'Send Message', 'मराठी': 'संदेश पाठवा', 'हिन्दी': 'संदेश भेजें'},
      'no_messages': {'English': 'No messages yet', 'मराठी': 'अजून कोणतेही संदेश नाहीत', 'हिन्दी': 'अभी कोई संदेश नहीं'},
      'no_notifications': {'English': 'No notifications', 'मराठी': 'कोणत्याही सूचना नाहीत', 'हिन्दी': 'कोई सूचना नहीं'},
      'personal_information': {'English': 'Personal Information', 'मराठी': 'वैयक्तिक माहिती', 'हिन्दी': 'व्यक्तिगत जानकारी'},
      'full_name': {'English': 'Full Name', 'मराठी': 'पूर्ण नाव', 'हिन्दी': 'पूरा नाम'},
      'mobile_number': {'English': 'Mobile Number', 'मराठी': 'मोबाईल क्रमांक', 'हिन्दी': 'मोबाइल नंबर'},
      'select_disease': {'English': 'Select disease', 'मराठी': 'आजार निवडा', 'हिन्दी': 'बीमारी चुनें'},
      'no_disease': {'English': 'No Disease', 'मराठी': 'आजार नाही', 'हिन्दी': 'कोई बीमारी नहीं'},
      'diabetes': {'English': 'Diabetes', 'मराठी': 'मधुमेह', 'हिन्दी': 'मधुमेह'},
      'hypertension': {'English': 'Hypertension', 'मराठी': 'उच्च रक्तदाब', 'हिन्दी': 'उच्च रक्तचाप'},
      'tuberculosis': {'English': 'Tuberculosis', 'मराठी': 'क्षयरोग', 'हिन्दी': 'तपेदिक'},
      'malaria': {'English': 'Malaria', 'मराठी': 'मलेरिया', 'हिन्दी': 'मलेरिया'},
      'anemia': {'English': 'Anemia', 'मराठी': 'अशक्तपणा', 'हिन्दी': 'एनीमिया'},
      'yes': {'English': 'Yes', 'मराठी': 'होय', 'हिन्दी': 'हाँ'},
      'no': {'English': 'No', 'मराठी': 'नाही', 'हिन्दी': 'नहीं'},
    };
    return data[key]?[language.value] ?? key;
  }
}
