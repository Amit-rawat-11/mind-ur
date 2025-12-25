import 'package:cloud_firestore/cloud_firestore.dart';

class ApiConfigService {
  static final _firestore = FirebaseFirestore.instance;

  static String? geminiKey;
  static String? openRouterKey;

  static Future<void> load() async {
    final doc = await _firestore
        .collection('config')
        .doc('api')
        .get();

    if (!doc.exists) {
      throw Exception('API config not found in Firestore');
    }

    final data = doc.data()!;

    openRouterKey = data['openRouterKey'];
  }
}
